require_relative "base_interpreter"
require 'haml'

#JSON intrepreter, should be the root class for all Basie interpreters.
class Basie::HTMLInterpreter < Basie::Interpreter

	def initialize(params={})
		@route = "/html"
		super(params)
	end

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

	def parse_for_column(column, columnsettings)

		columnsettings.each do |statement|
			#check to see if this is an htag statement.
			if @@htaghash.has_key?(statement)
				column.params[:htag] = @@htaghash[statement]
			end
		end

		#set a default htag parameter based on the current type of the object.
		column.params[:htag] = column.params[:htag] || @@htaghash[column.type]
	end

	def setup_paths(table)
		#table should be a symbol to the name of the table.
		fullroute = "#{@route}/#{table.name}"

		##############################################################
		## HTML-BASED data access.
		## /html/[name] - the entire table
		## /html/[name]/[query] - queries searchable, or id/hash
		## /html/[name]/[column]/[match] - queries all database rows that match expected

		#register a path to the table.
		app.get (fullroute) do

			#get the data
			res = table.entire_table

			#set up the output.
			o = "%table"

			#check to see if we have a null table.
			if res.length == 0
				#then return an empty table.
				return haml o
			end
			
			#get the column names from the first row
			o += "\n\t%tr"

			#populate the header row
			res[0].each_key{|k| o += "\n\t\t%th #{k}"}

			#populate the data rows
			res.each do |entry|
				o += "\n\t%tr"
				entry.each_value{|v| o+= "\n\t\t%td #{v}"}
			end

			haml o
		end
	end
end

