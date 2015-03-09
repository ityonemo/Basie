#column.rb
#contains the Column class which handles column definitions.

#creates an error which happens when there is a probelm in Basie definition
class Basie::DefinitionError < StandardError  
end  

class Basie::Column
	attr_reader :name		#column name
	attr_reader :type		#column type
	attr_reader :params		#hash of parameter strings.

	def initialize(columnline)
		#check to make sure our columnline is not blank
		if columnline.strip.length == 0
			raise Basie::DefinitionError, "Basie Column Definitions must not be blank"
		end

		#eliminate from consideration everything past the 
		lineparts = columnline.strip.split("#")

		#check to make sure we haven't put in an all-comment line.
		if lineparts[0].length == 0
			raise Basie::DefinitionError, "Basie Column Definitions must not be comments"
		end

		#create a couple of temporary pieces to really get down to the parsing.
		dbtokens = lineparts[0].split.map{|s| s[/\w+/]}.compact
		comments = lineparts[1..-1]

		@type = type_of(dbtokens)
		@name = dbtokens[1][/\w+/].to_sym
		@params = params_of(comments)

		#other consistency checks.
		#first, primary key should have name id.
		if (@type == :primary_key) && (@name != :id)
			raise Basie::DefinitionError, "Basie primary keys must be named \"id\""
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
			raise Basie::DefinitionError, "unidentified column type class: " + typetoken
		end	
	end
	private :type_of

	@@htaghash = {
		#custom htags as defined by comments
		"tel" 			=> :tel,
		"url" 			=> :url,
		"email" 		=> :email,
		"suppress" 		=> :suppress,	#note that there is no "suppress" type in the standard HTML lexicon.
		"hash" 			=> :suppress,
		"options" 		=> :option,
		"picker" 		=> :picker,
		#as defined by type
		:integer		=> :number,
        :bigint			=> :number,
        :numeric		=> :number,
        :date			=> :date,
        :timestamp		=> :datetime,
        :varchar		=> :text,
        :char			=> :text,
        :foreign_key	=> :text,
        :text			=> :textarea,
        :boolean		=> :checkbox,
        :blob			=> :file
	}

	def params_of(comments)
		params = {}
		comments.each do |statement|
			#strip the statement.
			statement.strip!

			puts statement

			#check to see if this is an htag statement.
			if @@htaghash.has_key?(statement)
				params[:htag] = @@htaghash[statement]
			end
		end

		#set a default htag parameter based on the current type of the object.
		unless params[:htag]
			params[:htag] = @@htaghash[@type]
		end

		params
	end
	private :params_of
end