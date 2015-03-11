require_relative "base_interpreter"
require 'haml'

#JSON intrepreter, should be the root class for all Basie interpreters.
class Basie::HTMLInterpreter < Basie::Interpreter

	def initialize(params={})
		@route = "/html"
		super(params)
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

