require 		'json'
require_relative "base_interface"

#A JSON intrepreter for basie.
class Basie::JSONInterface < Basie::Interface

	def initialize(params={})
		@root = "/json"

		#register the JSON mime type with the application.
		app.configure do
  		app.mime_type :json, 'application/json'
  	end

		super(params)
	end

	#################
	#ROUTE OPTIONS:
	# :all      -all routes
	# :table    -get the full table
	# :id       -get a row by id (or hash)
	# :search   -search for a row
	# :query    -search for a row by query

	#JSON does nothing special for the table and column readings.  So we may skip directly to:

	def setup_paths(table)
		#table should be a symbol to the name of the table.
		tableroot = "#{@root}/#{table.name}"

		##############################################################
		## JSON-BASED data access.
		## /json/[name] - the entire table
		## /json/[name]/[query] - queries searchable, or id/hash
		## /json/[name]/[column]/[match] - queries all database rows that match expected

		#register a path to the table.
		route_check(:table) do
			app.get (tableroot) do
				begin
					content_type :json
					table.entire_table(:session => session).to_json
				rescue SecurityError
					403
				end
			end
		end

		route_check(:id) do
			app.get (tableroot + '/:id') do |id|
				begin
					content_type :json
					table.data_by_id(id, :session => session).to_json
				rescue SecurityError
					403
				rescue ArgumentError
					400
				rescue Basie::NoEntryError
					404
				end
			end
		end

		route_check(:search) do
			#nothing, for now.
		end

		route_check(:query) do
			app.get (tableroot + "/:column/:query") do |column, query|
				begin
					content_type :json
					table.data_by_query(column, query, :session => session).to_json
				rescue SecurityError
					403
				rescue ArgumentError
					400
				rescue Basie::NoEntryError
					404
				end
			end
		end
	end
end
