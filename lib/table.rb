#table.rb
#contains the Table class which handles table definitions.

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
	attr_reader :columns
	attr_reader :foreignkeys
	attr_reader :searchcolumns
	attr_reader :basie

	#def columns(opt = nil)
	#	if (@properties[:use_hash] || (opt == :all))
	#		@columns.reject{|k,h| h.type == "primary_key" || h.htag == "suppress"}
	#	else
	#		@columns
	#	end
	#end

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
		@searchcolumns = nil

		#then realize the input
		analyze init_txt

		#connect to the database, then create the database entries.
		@basie.connect do |db|
			#check to see if the table exists.
			if (db.table_exists?(name))
				#FOR NOW, DO NOTHING.  IN THE FUTURE, PARSE INITIALIZATION TEXT AND ADJOIN DATA
				#TO THE EXISTING DATABASE.

				#create a warning about overwriting table name.
				$stderr.puts("Warning: modifying the existing table #{name}")
			else
		    	#generate an initialization command that we will execute on the database.
    			init_cmd = "db.create_table?(:#{name}) do\n#{init_txt}\nend"	#generate the command
    			eval(init_cmd)													#execute it.
			end
		end
		#save this object to basie
		@basie.tables[name] = self
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
					#parse_setting sline
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
	end
	private :parse_setting

	def parse_column(line)
		#scan the line.
		cl = Basie::Column.new line

		#check to make sure this wasn't a blank line with no content.
		@columns[cl.name] = cl
		#if this column is a foreign key column, then add it to the foreign key list.
		if (cl.type == "foreign_key")
			foreignkeys[cl.name] = cl.params[0].to_sym
		end
	end
	private :parse_column

	#def columns_select(opt = nil)
		#generates a select statement that has appropriate substitutions for hash selected columns.
		#you can either pass :all to columns_select, which will force-generate all columns, or
		#you can pass a foreign key column which will be directly left-joined.

	#	c = @foreignkeys.has_key?(opt) ? columns : columns(opt)

		#a select statement will just push out a string representation of the table columns.
		#however, if we are a foreign key, and the foreign table is a :use_hash table, then we
		#should substitute the column with the "[table]_hash" column that will appear as a result
		#of a join with the hash SQL view that we've generated.
	#	s0 = c.keys.map do |col|
	#		if (c[col].type == "foreign_key")
	#			ftable = @foreignkeys[col]
	#			if (ftable == opt)
					#then we're choosing to, in the place of the specified column, do an entire left join.  pick out the columns.
	#				$TABLES[ftable].columns.keys.map{|k| k.to_s}.join(', ')

					#TODO: check to make sure that we don't have duplicate column names.
	#			else
					#if the foreign key table is a search table, we're going to specify both the hash and the search term.
					#cache the search term.
	#				sc = ($TABLES[ftable].searchcolumns == nil) ? "" : ", #{@name}_#{col}_search";

					#make sure to substitute the hash column in the place of the original column name, then the search (if necessary)
	#				($TABLES[ftable].properties[:use_hash]) ? "#{@name}_#{col}_hash AS #{col}" + sc : col.to_s  
	#			end
	#		else
	#			col 
	#		end
	#	end.join(', ') 

		#generates a string that is a select statement that compiles all of the left joins for hash substitution.
	#	s1 = @foreignkeys.keys.reject{|k| !$TABLES[@foreignkeys[k]].properties[:use_hash]}
	#		.map do |k|
	#			fk = @foreignkeys[k] 
	#			(fk == opt) ? "LEFT JOIN #{fk} ON #{@name}.#{k}=#{fk}.id" : "LEFT JOIN #{@name}_#{k}_hash ON #{@name}.#{k}=#{@name}_#{k}_hash.id"
	#		end.join(' ')

	#	"SELECT #{s0} FROM #{@name} #{s1}"
	#end

	#def hamlform(path)
		#generates an html form for the table that goes to the given path.
	#	output = "%form##{name}_form(action='#{path}' method='POST')\n"
	#	columns.each do |k,c|
	#		output += "\t%label\##{k}_label\n\t\t#{k}\n"
	#		output += (c.htag == "textarea") ? "\t\t%textarea\##{k}_input(name='#{k}')\n" : "\t\t%input\##{k}_input(type='#{c.htag}' name='#{k}')\n"
	#	end
	#	output += "\t%input#submit_input(type='submit')"
	#end

	#def reformat_input_list(list)
		#checks a list of rows, then massages the input to be compatible with the basie DB input.

	#	list.map do |entry|
	#		temp = {}						#since we can't 'map' a hash, set up a temporary hash where we will stash values.
	#		entry.each do |column,data|
	#			csym = column.to_sym
	#			if (columns.has_key?(csym))
	#				temp[csym] = convert(csym, data)
	#			end
	#		end
	#		temp
	#	end
	#end

	#def hashgen(id)
		#generates a hash given an id for the table.
	#	Base64.urlsafe_encode64(Digest::SHA256.digest("basie" + $HASHSALT.to_s + @name.to_s + id.to_s))[0..11]
	#end

	#a convert method that converts a data string into the appropriate data type.
	#def convert(column, data)
		#tolerate empty data
	#	if (data == nil)
	#		return nil
	#	end

		#redo the data based on the type.
	#	case @columns[column].type
	#	when 'string', 'varchar', 'char', 'text'
	#		data
	#	when 'integer', 'bigint'
	#		data.to_i
	#	when 'numeric'
	#		data.to_d
	#	when 'double'
	#		data.to_f
	#	when 'date'
	#		begin
	#			Date.parse(data)
	#		rescue
	#			puts "#{data} invalid date."
	#			nil
	#		end
	#	when 'timestamp'
	#		begin
	#			Datetime.parse(data)
	#		rescue
	#			puts "{data} invalid datetime."
	#			nil
	#		end
	#	when 'boolean'
	#		(data == 'true') ? true : false
	#	when 'foreign_key'
			#do our foreign key magic here.  there may be a better way to do this by aggregating 
			#requests and making less trips to mysql, but let's worry about that later.

			#check to make sure the foreign key that we're requesting is searchable.
			#for tables that are hash- or id- driven, the association is fragile across
			#databases, so we won't allow those.

			#TODO:  output some sort of warning message in that situation.
	#		if ($TABLES[@foreignkeys[column]].searchcolumns == nil)
	#			return nil
	#		end

			#set the names of the table and the name of the search column.
			#note that we are using the "pre-cached id/hash/search association view"
	#		tablename = "#{@name}_#{column}_hash".to_sym
	#		searchname = "#{@name}_#{column}_search".to_sym

	#		db = db_connect
	#		begin
				#grab the data
	#			res = db[tablename].where(searchname => data)

				#TODO:  figure out what happens if this search term doesn't exist, and then output some sort of warning message.
	#			if (res.first == nil)
	#				puts "warning: could not find entry #{data} in foreign key search of table #{$TABLES[@foreignkeys[column]]}"
	#				nil
	#			else
	#				res.first[:id]
	#			end
	#		ensure
	#			db.disconnect
	#		end
	#	end
	#end
	#private :convert
end
