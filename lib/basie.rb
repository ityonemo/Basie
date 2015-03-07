#BASIE.rb
#contains the Basie class which handles most of the database-related things.
require 'sequel'
require 'sinatra'
require 'stringio'

#basie components.
require_relative "table"

#basie is an environment that handles access to a database.
class Basie
	def login; @dblogin; end
	def pass; @dbpass; end
	def host; @dbhost; end
	def name; @dbname; end
	def db; @db; end

	def initialize(params)
		@dblogin = params[:login] || "www-data"
		@dbpass = params[:pass] || ""
		@dbhost = params[:host] || "localhost"
		@dbname = params[:name] || raise(ArgumentError, "database name required!")
	end

	def connect()
		#connects to a database.  Sets the internal db variable to the connection.
		@db = Sequel.mysql(@dbname, :user => @dblogin, :password => @dbpass, :host => @dbhost)
		if block_given?
			begin
				yield
			ensure
				@db.disconnect
			end
		end
	end

	def disconnect
		#disconnects from the database.
		@db.disconnect
	end

	#creates a table using a basie-style definition
	def create(sym, file = nil)
		#check the input.
		unless (Symbol === sym)
			raise(ArgumentError, "first argument to create must be a symbol")
		end

		#return the new tables created.  Note that this will use the definition of table (as created below.)
		case file
		when File
			Basie::Table.new sym, file
		when String
			Basie::Table.new sym, StringIO.new(file)
		when NilClass
			#create the path based on our sinatra setting.
			path = "#{File.dirname(__FILE__)}/tables/#{sym}.basie"
			Basie::Table.new sym, File.new(path)
		else
			raise(ArgumentError, "attempting to create a table with an odd second input")
		end
	end
end

