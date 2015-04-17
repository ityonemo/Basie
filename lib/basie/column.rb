#column.rb
#contains the Column class which handles column definitions.

class Basie::Column
	attr_reader :name		#column name
	attr_reader :type		#column type
	attr_reader :table		#column's parent table
	attr_reader :basie 		#column's parent basie
	attr_reader :params		#hash of parameter strings.

	def initialize(columnline, table = nil)
		#set our parent reference values
		@table = table

		@basie = @table.basie if @table;

		#check to make sure our columnline is not blank
		raise Basie::DefinitionError, "Basie Column Definitions must not be blank" if columnline.strip.length == 0

		#eliminate from consideration everything past the 
		lineparts = columnline.strip.split("#")

		#check to make sure we haven't put in an all-comment line.
		raise Basie::DefinitionError, "Basie Column Definitions must not be comments" if lineparts[0].length == 0

		#create a couple of temporary pieces to really get down to the parsing.
		dbtokens = lineparts[0].split.map{|s| s[/\w+/]}.compact
		comments = lineparts[1..-1]

		@type = type_of(dbtokens)
		@name = dbtokens[1][/\w+/].to_sym

		@params = {}

		#check for universal directives in comments
		@table.suppresslist.push @name if @table && (comments.include? "suppress")

		set_params(comments)

		#other consistency checks.
		#first, primary key should have name id.
		raise Basie::PrimaryKeyError, "Basie primary keys must be named \"id\""  if (@type == :primary_key) && (@name != :id)

		#second, foreign keys should exist.
		if (@type == :foreign_key)
			#retrieve the foreign key from the parsing of the line.
			fname = dbtokens[2][/\w+/].to_sym

			#do a consistency check here.
			raise Basie::NoTableError, "Basie foreign key doesn't exist" unless @basie.tables.has_key?(fname)

			#we're ok. so set the table's foreign key store.
			@table.foreignkeys[@name] = fname
		end
	end

	@@typehash = {'Integer' => :integer,
			'Fixnum' => :integer,
			'Bignum' => :bigint,
			'BigDecimal' => :numeric,
			'Numeric' => :numeric,
			'File' => :blob,
			'Float' => :double,
			'Date' => :date,
			'DateTime' => :timestamp,
			'TrueClass' => :boolean,
			'FalseClass' => :boolean}

	def type_of(dbtokens)
		typetoken = dbtokens[0]
		case typetoken
		#ruby types that are going to map to sql types
		when "Integer", "Fixnum", "Bignum", "BigDecimal", "Numeric", "File", "Float", "Date", "DateTime", "TrueClass", "FalseClass"
			@@typehash[typetoken]

		#idempotent class types, are identical to their sql types
		when "integer", "bigint", "numeric", "blob", "double", "date", "timestamp", "boolean", "varchar", "char", "text"
			typetoken.to_sym

		#two special types that are not going to map to real sql types
		when "primary_key", "fixed_key", "foreign_key"
			typetoken.to_sym

		#the ruby string type is ambiguous enough that we have to do a little bit of further decoding.
		when "String"

			idx = dbtokens.find_index("text")
			#did we specify that this is text?
			if (idx != nil) && (dbtokens[idx + 1] == "true")
				:text
			else
				#did we specify that this is a varchar or char?
				idx2 = dbtokens.find_index("fixed")
				if (idx2 != nil) && (dbtokens[idx2 + 1] == "true")
					:char
				else
					:varchar
				end
			end
		else
			raise Basie::BadTypeError, "unidentified column type class: " + typetoken
		end	
	end
	private :type_of

	def set_params(comments)
		#pass all comments to the interfaces
		Basie.interfaces.each do |interface|
			interface.parse_for_column(self, comments)
		end
	end
	private :set_params
end