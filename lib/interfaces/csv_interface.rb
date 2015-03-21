require_relative "base_interface"

#A JSON intrepreter for basie.
class Basie::CSVInterface < Basie::Interface

	def initialize(params={})
		@root = "/csv"

		#register the JSON mime type with the application.
		app.configure do
  			app.mime_type :csv, 'text/csv'
  		end

		super(params)
	end

	def self.to_csv(data, first = true)
		#generates CSV data from a ruby object.  This could be just one hash or an array of hashes.
		#preconditions:
		# if it's an array, each hash should have the same keys, and the keys should be in the same canonical order.
		# undefined results occur if these keys are out of order.
		case data
		when Array
			header = data[0].each_key.map{|k| "\"#{k}\""}.join(",") + "\n"
			return header + data.each.map{|h| to_csv(h, false)}.join()
		when Hash
			header = first ? data.each_key.map{|k| "\"#{k}\""}.join(",") + "\n" : ""
			return header + data.each_value.map{|v| "\"#{v}\""}.join(",") + "\n"
		else
			raise ArgumentError, "to_csv requires appropriate data types, encountered bad type " + data.class.to_s
		end
	end

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
				content_type :csv

				res = table.entire_table

				Basie::CSVInterface.to_csv(res)
			end
		end

		route_check(:id) do
			app.get (tableroot + '/:id') do |id|
				begin
					content_type :csv
					res = table.data_by_id(id)
					Basie::CSVInterface.to_csv(res)
				rescue ArgumentError
					400
				rescue Basie::NoEntryError
					404
				end
			end
		end

		route_check(:query) do
			app.get (tableroot + '/:column/:query') do |column, query|
				begin
					content_type :csv
					res = table.data_by_query(column, query)
					Basie::CSVInterface.to_csv(res)
				rescue ArgumentError
					400
				rescue Basie::NoEntryError
					404
				end
			end
		end
	end
end