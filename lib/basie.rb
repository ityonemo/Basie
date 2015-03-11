#BASIE.rb
#contains the Basie class which handles most of the database-related things.
require 'sequel'
require 'sinatra'
require 'stringio'

#basie components.
require_relative "table"
require_relative "column"
require_relative "base_interpreter"
require_relative "json_interpreter"
require_relative "html_interpreter"
#require_relative "csv_interpreter"

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
	def create(sym, params = {})
		#check the input.
		unless (Symbol === sym)
			raise(ArgumentError, "first argument to create must be a symbol")
		end

		params[:basie] = self

		#return the new tables created.  Note that this will use the definition of table (as created below.)
		#then set that value to the table variable.
		table = if (File === params[:file])
					#check to see if we're delivering a file directly
					Basie::Table.new sym, params[:file].read, params
				elsif (String === params[:path])
					#are we delivering a path string?
					Basie::Table.new sym, File.new(params[:path]).read, params
				elsif (String === params[:definition])
					#are we delivering a definition directly?
					Basie::Table.new sym, params[:definition], params
				else
					#create the path based on our internal setting.
					path = File.join(@settings[:tabledir],"#{sym}.basie")
					Basie::Table.new sym, File.new(path).read, params
				end

		#now, register with the interpreters.
		Basie::Interpreter.interpreters.each do |interpreter|
			interpreter.setup_paths(table)
		end
	end
end

#by default, activate several different Basie interpreters.
Basie::JSONInterpreter.new
Basie::HTMLInterpreter.new
#Basie::CSVInterpreter.new