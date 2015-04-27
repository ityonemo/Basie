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
	attr_reader :suppresslist
	attr_reader :columns

	#convenience variables that store SQL specifiers to control access.
	attr_reader :public_access

	def initialize(name, init_txt, params = {})
		#check to make sure our arguments are all right.
		raise ArgumentError, "incorrect arguments for initializing a table" unless (Symbol === name) && (String === init_txt) && (Hash === params)

		#cache a link to the parent basie object
		@basie = params[:basie]
		raise ArgumentError, "failure to pass the parent Basie object" unless (Basie === @basie)

		#store the name.
		@name = name
		#initialize a (usually blank) properties object.
		@settings = params
		#initialize a blank columns hash
		@columns = {}
		#initialize a foreign keys hash
		@foreignkeys = {}
		#initialize a reference views array.
		@referenceviews = []
		#create an array to hold the columns that we're going to suppress
		@suppresslist = []

		#then realize the input
		analyze init_txt

		#now set public read and write access filters for this table.
		@public_access = @basie.get_public_access(@name)

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

			#next, create foreign table reference views
			@foreignkeys.each_key {|k| create_reference_view(k, db)}
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
			next if sline.length == 0

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

		#things to do when the label parsing has finished.
		if @settings[:use_label]
			#check to make sure
			@settings[:use_label].each do |label|
				if !@columns.has_key?(label.to_sym)
					raise Basie::NoLabelError, "no column corresponding to the desired label"
				end
			end
		end

		#and then suppress the hash column if applicable
		@suppresslist.push(:id) if (@settings[:use_hash])
	end
	private :analyze

	def parse_setting(line)
		#look for the "use_hash" setting
		@settings[:use_hash] ||= (line[0..7] == "use_hash")

		#look for the "label" setting.
		if /label\s/ =~ line[0..5]
			@settings[:use_label] = line.split[1..-1]
		end
	end
	private :parse_setting

	def parse_column(line)
		#scan the line, pass the current table.
		cl = Basie::Column.new line, self

		#check to make sure this wasn't a blank line with no content.
		@columns[cl.name] = cl

		#if this column is a foreign key column, then add it to the foreign key list.
	end
	private :parse_column

	#creates a reference view for each foreign key column.
	def create_reference_view(column, db)
    	#assign the actual foreign table
    	fname = @foreignkeys[column]
    	ftable = @basie.tables[fname]

    	#check to see if the foreign table uses hash.

    	if ftable.settings[:use_hash]
    		#generate the view name.  The view name is table + column + foreignname + "_lookup"
    		vname = "#{@name}_#{column}_lookup"

    		#generate the select statement
    		select = "SELECT id, hash FROM #{fname}"

    		db.create_or_replace_view(vname, select)

    		@referenceviews.push vname
    	end
	end
	private :create_reference_view

	##################################################################3
	## DATA HELPER FUNCTIONS

	#helper function, which makes input hashes or arrays look nice.
	def reformat_input(input, params = {})
		#checks a list of rows, then massages the input to be compatible with the basie DB input.
		case input
		when Array
			input.map {|data| reformat_input(data, params)}
		when Hash
			temp = {}	#we can't do a map on the hash data type
			input.each do |column, data|
				csym = column.to_sym

				#check the reject parameter to see if our symbol is in the rejection list.
				next if params[:reject] && params[:reject].include?(csym)

				temp[csym] = data if @columns.has_key?(csym)
			end
			temp
		else
			raise ArgumentError, "input must be a hash or array of hashes"
		end
	end

	#forwarded cleanup responsibilities from basie.  Mostly just for testing purposes.
	def cleanup(db)
		db.drop_table?(@name)
		@referenceviews.each{|view| db.drop_view(view, :if_exists => true)}
	end

	##########################################################################
	## HASH-EY FUNCTIONS
	def is_hash?(string)
		if String === string
			(string.length == @basie.settings[:hashlen]) && ( /([\w\-\_]*)/.match(string)[1].length == @basie.settings[:hashlen])
		else
			false
		end
	end

	def hashgen(id)
		#generates a hash given an id for the table.
		Base64.urlsafe_encode64(Digest::SHA256.digest(@basie.settings[:hashsalt] + @name.to_s + id.to_s))[0...@basie.settings[:hashlen]]
	end

	def brandhash(id)
		#brands an item with a certain id with its appropriate id
		#note basie should be connected when running this.
		@basie.db[@name].where(:id => id).update(:hash => hashgen(id)) if @settings[:use_hash]
	end
end
