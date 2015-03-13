require_relative "base_interpreter"

#A JSON intrepreter for basie.
class Basie::JSONInterpreter < Basie::Interpreter

	def initialize(params={})
		@route = "/json"

		#register the JSON mime type with the application.
		app.configure do
  			app.mime_type :json, 'application/json'
  		end

		super(params)
	end

	#JSON does nothing special for the table and column readings.  So we may skip directly to:

	def setup_paths(table)
		#table should be a symbol to the name of the table.
		fullroute = "#{@route}/#{table.name}"

		##############################################################
		## JSON-BASED data access.
		## /json/[name] - the entire table
		## /json/[name]/[query] - queries searchable, or id/hash
		## /json/[name]/[column]/[match] - queries all database rows that match expected

		#register a path to the table.
		app.get (fullroute) do
			content_type :json
			table.entire_table.to_json
		end

		app.get (fullroute + '/:query') do |query|
			content_type :json

			table.data_by_id(query).to_json
		end

		app.get (fullroute + "/:column/:query") do |column, query|
			content_type :json

			table.data_by_query(column, query).to_json
		end
	end
end