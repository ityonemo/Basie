require_relative "base_interpreter"
require 'haml'

#JSON intrepreter, should be the root class for all Basie interpreters.
class Basie::HTMLInterpreter < Basie::Interpreter

	def initialize(params={})
		@route = "/html"
		super(params)
	end

	def self.to_table(data)
		header = "%table"

		#check to see if our table is going to be blank.
		if data.length == 0 
			return header
		end

		#add the header row which contains all of the common keys.
		header += "\n\t%tr" + data[0].keys.map{|k| "\n\t\t%th #{k}"}.join
		#then add all of the data rows.
		header + data.each.map{|h| "\n\t%tr" + h.values.map{|v| "\n\t\t%td #{v}"}.join}.join
	end

	def self.to_dl(data)
		#convert a single hash data into a dl.
		#set up the output.
		"%dl" + data.keys.map{|k| "\n\t%dt #{k}\n\t%dd #{data[k]}"}.join
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
			haml Basie::HTMLInterpreter.to_table(res)
		end

		app.get (fullroute + "/:query") do |query|
			#get the data
			res = table.data_by_id(query)
			haml Basie::HTMLInterpreter.to_dl(res)
		end

		app.get (fullroute + "/:column/:query") do |column, query|
			#get the data
			res = table.data_by_query(column, query)
			haml Basie::HTMLInterpreter.to_dl(res)
		end
	end
end

