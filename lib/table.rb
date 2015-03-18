#table.rb
#contains the Table class which handles table definitions.

#hash generation, for hash-ing stuff.
require	'digest'
require 'base64'

#include table accessors methods.
require_relative 'table_accessors'

#forward the existence of the Basie class.
class Basie; end

#forward the existence of the Basie Column class.
class Basie::Column; end

#define the basie table class.
class Basie::Table
	attr_reader :name
	attr_reader :settings
	attr_reader :foreignkeys
	attr_reader :basie

	def columns
		#cast out any columns which are a "primary key".  These will be subbed for the hash.
		if @settings[:use_hash]
			@columns.reject{|k,h| h.type == :primary_key}
		else
			@columns
		end
	end

	def initialize(name, init_txt, params = {})
		#check to make sure our arguments are all right.
		unless (Symbol === name) && (String === init_txt) && (Hash === params)
			raise ArgumentError, "incorrect arguments for initializing a table"
		end

		#cache a link to the parent basie object
		@basie = params[:basie]
		unless (Basie === @basie)
			raise ArgumentError, "failure to pass the parent Basie object"
		end

		#store the name.
		@name = name
		#initialize a (usually blank) properties object.
		@settings = params
		#initialize a blank columns hash
		@columns = {}
		#initialize a foreign keys array
		@foreignkeys = {}

		#then realize the input
		analyze init_txt

		#connect to the database, then create the database entries.
		@basie.connect do |db|
			#check to see if the table exists.
			if (db.table_exists?(name))
				#FOR NOW, DO NOTHING.  IN THE FUTURE, PARSE INITIALIZATION TEXT AND ADJOIN COLUMNS
				#TO THE EXISTING DATABASE.

				#create a warning about overwriting table name.
				$stderr.puts("Warning: modifying the existing table #{name}")
			else
		    	#generate an initialization command that we will execute on the database.
    			init_cmd = "db.create_table?(:#{name}) do\n#{init_txt}\nend"	#generate the command
    			eval(init_cmd)													#execute it.
			end
		end
	end

	#the analyze directive takes the sequel initialization file, together with
	#any comments, and turns it into the basie internal model.
	def analyze(init_txt)
		#comments in the header may be settings.
		header = true
		init_txt.each_line do |line|
			#save the line with beginning and ending whitespace removed.
			sline = line.strip
			#skip blank lines
			if sline.length == 0
				next
			end
			#check to see if we are strictly a comment line
			if (sline[0] == "#")
				#parse as if it is a settings
				if header
					parse_setting sline[1..-1]
					Basie.interfaces.each do |interface|
						interface.parse_for_table(self, sline[1..-1])
					end
				end
			else
				#we are no longer in the header, and there is content.
				header = false
				parse_column sline
			end
		end
	end
	private :analyze

	def parse_setting(line)
		#look for the "use_hash" setting
		if line[0..7] == "use_hash"
			@settings[:use_hash] = true
		end
	end
	private :parse_setting

	def parse_column(line)
		#scan the line.
		cl = Basie::Column.new line

		#check to make sure this wasn't a blank line with no content.
		@columns[cl.name] = cl
		#if this column is a foreign key column, then add it to the foreign key list.
	end
	private :parse_column


	##########################################################################
	## HASH-EY FUNCTIONS
	def is_hash?(string)
		(string.length == @basie.settings[:hashlen]) && ( /([\w\-\_]*)/.match(string)[1].length == @basie.settings[:hashlen])
	end

	def hashgen(id)
		#generates a hash given an id for the table.
		Base64.urlsafe_encode64(Digest::SHA256.digest(@basie.settings[:hashsalt] + @name.to_s + id.to_s))[0...@basie.settings[:hashlen]]
	end

	def brandhash(id)
		#brands an item with a certain id with its appropriate id
		#note basie should be connected when running this.
		if @settings[:use_hash]
			@basie.db[@name].where(:id => id).update(:hash => hashgen(id))
		end
	end
end
