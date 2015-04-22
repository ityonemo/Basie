#BASIE.rb
#contains the Basie class which handles most of the database-related things.
require 'sequel'
require 'sinatra'
require 'stringio'

#basie components.
require_relative "table"
require_relative "column"
require_relative "basie_errors"
require_relative "interfaces/base_interface"
require_relative "interfaces/json_interface"
require_relative "interfaces/html_interface"
require_relative "interfaces/csv_interface"
require_relative "interfaces/post_interface"
require_relative "interfaces/user_interface"


#basie is an environment that handles access to a database.
class Basie
	#full access objects
	attr_accessor :settings

	#half-access objects
	attr_reader :login
	attr_reader :pass
	attr_reader :host
	attr_reader :name
	attr_reader :db
	attr_reader :tables

	##############################################################################
	## MANAGEMENT OF INTERFACES

	#a list of interfaces that we're using.
	@@interfaces = []
	#and a half-accessor for that.
	def self.interfaces; @@interfaces; end
	#purge clears out the interfaces, but this should only be useful during debug phase.
	def self.purge_interfaces; @@interfaces = []; end

	#the interpret directive causes Basie to activate an interpreter object.
	def self.activate(what, params = {})
		#use a little bit of reflection to instantiate basie interpreter.
		case what
		when Symbol
			stxt = what.to_s[/\w+/]
			#check to see if it is an internal class.
			if eval("defined? Basie::#{stxt}Interface")
				c = eval("Basie::#{stxt}Interface")
			elsif eval("defined? #{stxt}")
				c = eval(what.to_s)
			else
				raise ArgumentError, "#{stxt} does not exist."
			end

			unless Class === c
				raise ArgumentError, "#{stxt} is not a class."
			end

			unless c.superclass == Basie::Interface
				raise ArgumentError, "class #{stxt} is not an interface."
			end

			#instantiate the class
			c.new params
		when Class
			if what.superclass == Basie::Interface
				what.new params
			else
				raise ArgumentError, "class #{what} is not an interface."
			end
		when Array
			#also allow us to do arrays.
			what.each{|interface| self.activate(interface)}
		when Hash
			#or hashes, if we wish to add parameters.
			what.each{|interface, parameters| self.activate(interface, parameters)}
		else
			raise ArgumentError, "unknown what"
		end
	end

	##############################################################################
	## ACCESS SCHEMES

	@@access_generator = nil

	def self.set_access_generator(g);
		raise ArgumentError, "access generator must be a proc" unless Proc === g
		@@access_generator = g;
	end

	def self.set_session_access(q)
		#q should be the result of a database query
		session[:access] = @@access_generator.call(q)
	end

	def self.access_control?; return @@access_generator != nil; end

	#an access generator is designed to do the following:
	# when a user logs on to the system, the access generator produces a hash of
	# two hashes, a read hash and a write hash.  The read hash is a lookup table
	# specifying for each table name either "" for full access or a control string
	# "WHEN <string>" which when appended to the MySQL string filters the
	# output.

	# The write hash is a lookup table specifying for each table name a
	# lambda which takes a potential input and filters it to conform with
	# specifications and prohibit malicious input.  The lambda may output nil,
	# signifying an access error.

	# The {:read, :write} hash is then saved into the session[:access], table
	# accessors will look this up and use them..

	# the access generator should also implement returning a call with :public
	# that which sets read/write permissions for the general public

	# more detailed permissions structures will come in future versions.

	##############################################################################
	## MANAGEMENT OF TABLES

	#creating a new basie object.
	def initialize(params)
		@login = params[:login] || "www-data"
		@pass = params[:pass] || ""
		@host = params[:host] || "localhost"
		@name = params[:name] || raise(ArgumentError, "database name required!")

		#create a blank settings object.
		@settings = {}
		#allow one to pass the root and tabledir settings directly into the constructor.
		@settings[:root] = params[:root] ? params[:root] : Dir.pwd
		@settings[:tabledir] = File.join(@settings[:root], (params[:tabledir] ? params[:tabledir] : "/tables"))

		#hashsalt data
		@settings[:hashsalt] = params[:hashsalt] || "basie"
		@settings[:hashlen] = params[:hashlen] || 12

		#create a blank tables object.
		@tables = {}
	end

	def connect()
		#connects to a database.  Sets the internal db variable to the connection.
		@db = Sequel.mysql(@name, :user => @login, :password => @pass, :host => @host)

		#please consider using the block form of this function to ensure database disconnection and resource retrieval
		if block_given?
			begin
				yield @db
			ensure
				disconnect
			end
		end
	end

	def disconnect
		#disconnects from the database.
		@db.disconnect
		@db = nil
	end

	#creates a table using a basie-style definition
	def create(tablename, params = {})
		#check the input.
		unless (Symbol === tablename)
			raise(ArgumentError, "first argument to create must be a symbol")
		end

		params[:basie] = self

		#return the new tables created.  Note that this will use the definition of table (as created below.)
		#then set that value to the table variable.
		table = if (File === params[:file])
					#check to see if we're delivering a file directly
					Basie::Table.new tablename, params[:file].read, params
				elsif (String === params[:path])
					#are we delivering a path string?
					Basie::Table.new tablename, File.new(params[:path]).read, params
				elsif (String === params[:definition])
					#are we delivering a definition directly?
					Basie::Table.new tablename, params[:definition], params
				else
					#create the path based on our internal setting.
					path = File.join(@settings[:tabledir],"#{tablename}.basie")
					Basie::Table.new tablename, File.new(path).read, params
				end

		#save this object to basie's table list
		@tables[tablename] = table

		#now, register with the interfaces.
		Basie.interfaces.each do |interface|
			interface.setup_paths table
		end
	end

	#an internal procedure that disposes of all of Basie's tables and views in an orderly fashion.
	#this mostly exists for testing purposes.
	def cleanup
		#do things in reverse.
		connect do |db|
			@tables.values.reverse_each do |table|
				table.cleanup(db)
			end
		end
	end

	#a directive that disables security and allows read/write access for all entities.
	#this is mostly useful for testing purposes
	def enable_full_access
		self.set_access_generator lambda do |x|
			h = {}; j = {}
			@tables.keys.each{|k| h[k] = ""}						#null string SQL filter
			@tables.keys.each{|k| j[k] = lambda{|l| l}}	#pass through lambda filter
			#the lambda should return a read/write pair with everything.
			{:read => h, :write => h}
		end
	end
end
