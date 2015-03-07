#table.rb
#contains the Table class which handles table definitions.

#forward the existence of the basie class.
class Basie
end

#define the basie table class.
class Basie::Table
	#half-accessor methods
	def name; @name; end
	def properties; @properties; end
	def foreignkeys; @foreignkeys; end
	def searchcolumns; @searchcolumns; end

	#def columns(opt = nil)
	#	if (@properties[:use_hash] || (opt == :all))
	#		@columns.reject{|k,h| h.type == "primary_key" || h.htag == "suppress"}
	#	else
	#		@columns
	#	end
	#end

	def initialize(name, tableio)
		#store the name.
		@name = name.to_sym
		#initialize a blank properties object.
		@properties = {}
		#initialize a blank columns hash
		@columns = {}
		#initialize a foreign keys array
		@foreignkeys = {}
		@searchcolumns = nil
	end

	#	lineindex = 1
	#	tabletext.each_line do |line|
			#is this line strictly a comment line?
	#		if (line.strip[0] == "#")
				#is it the first line?  It may be a properties annotation.
	#			if (lineindex == 1)
					#turn all of the elements in this line into things in the properties
					#TODO:  change the regexp to only grab hashtagged things.
	#				line.split.map{|e| e[/\w+/]}.compact.each do |e|
	#					@properties[e.to_sym] = true
	#				end
	#			end

				#check for a searchable tag, then assign the searchcolumns.
	#			checkstring = line.split("#")[1]
	#			if (checkstring[0..9] == "searchable")
	#				@searchcolumns = (checkstring.split)[1..-1]
	#			end
	#		end

			#either way scan the line 
	#		cl = BasieColumn.new(line)
	#		if (cl.has_content?)
	#			@columns[cl.name.to_sym] = cl
	#			if (cl.type == "foreign_key")
					#set up the foreign key.
	#				@foreignkeys[cl.name.to_sym] = line.split[2][/\w+/].to_sym
	#			end
	#		end

	#		lineindex += 1
	#	end

	#	@initializer = tabletext
	#end

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
