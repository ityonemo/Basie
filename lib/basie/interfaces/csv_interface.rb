require 'csv'
require_relative "base_interface"

#A CSV intrepreter for basie.
class Basie::CSVInterface < Basie::Interface

	def initialize(params = {})
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

	#converts a csv into an array of hashes.
	def self.array_from_csv(file)
		rownumber = 1
		columnnames = []
		output = []

		CSV.foreach(file) do |row|

			if (rownumber == 1)
				#assign this to the column names array.
				columnnames = row
			else
				#check for an empty row.
				if row.compact == []
					next
				end

				rowhash = {}

				(0..columnnames.length - 1).each {|idx|	rowhash[columnnames[idx]] = row[idx]}

				output << rowhash
			end

			rownumber += 1
		end

		output
	end

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
					content_type :csv

					res = table.entire_table(:session => session)

					Basie::CSVInterface.to_csv(res)
				rescue SecurityError
					403
				end
			end
		end

		route_check(:id) do
			app.get (tableroot + '/:id') do |id|
				begin
					content_type :csv

					res = table.data_by_id(id, :session => session)
					Basie::CSVInterface.to_csv(res)
				rescue SecurityError
					403
				rescue ArgumentError
					400
				rescue Basie::NoEntryError => e
					404
				end
			end
		end

		route_check(:query) do
			app.get (tableroot + '/:column/:query') do |column, query|
				begin
					content_type :csv
					res = table.data_by_query(column, query, :session => session)
					Basie::CSVInterface.to_csv(res)
				rescue SecurityError
					403
				rescue ArgumentError
					400
				rescue Basie::NoEntryError
					404
				end
			end
		end

		route_check(:postform) do
			app.get('/csvform') do
				haml "%form(action='/csv/#{table.name}' enctype='multipart/form-data' method='POST')\n\t%input(type='file' name='#{table.name}')\n\t%input(type='submit')"
			end
		end

		route_check(:post) do
			app.post (tableroot) do

				#save the parameter that has file info.
				dparam = params[table.name]
				#check to make sure we have a well-formed input here


				#TODO:  Double check that this error code is correct.
				return 400 unless dparam

				#TODO:  Set the error correctly here to reflect HTML type rejection.
				return 400 unless dparam[:type] == "text/csv"

				#parse the tempfile into a basie-compatible object
				rowlist = Basie::CSVInterface.array_from_csv(dparam[:tempfile])

				a = table.reformat_input(rowlist)

				begin
					table.insert_data(a, :session => session)

					200
				rescue SecurityError
					403
				end

			end
		end
	end
end
