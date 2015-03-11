require_relative "base_interpreter"

#JSON intrepreter, should be the root class for all Basie interpreters.
class Basie::JSONInterpreter < Basie::Interpreter

	def initialize
		#TODO:  Consider re-initializing the route name here.
		@route = "/json"

		#register the JSON mime type with the application.
		app.configure do
  			app.mime_type :json, 'application/json'
  		end

		super
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
			
			table.basie.connect do |db|
				#TODO:  Do a permissions check here.

				#figure out how to deal with this thing.
				db.fetch("SELECT * FROM #{table.name}").all.to_json
			end
		end

		#register a path to individual table data
#		get (fullroute + '/:query') do |query|
#			content_type :json
#			db = db_connect
#			begin
				#TODO:  Do a permissions check here.
				#permissions_check()

				#TODO:  Sanitize the data.
				#sanitize(id)

				#create some search term variables.
#				s2 = nil; s3 = nil

				#one possibility is that the table is searchable.  In this case, search for the query term 
				#in the searchable column.
#				searchcol = table.properties[:searchable]
#				if (searchcol != nil)
					#look for the search term in the table of interest.
#					q = db[name].select(:id).where(searchcol => query).first

#					if (q != nil); s2 = :id; s3 = q[:id]; end
#				end

#				if (s2 == nil)
#					if (table.properties[:use_hash])
						#we have failed to find term in the search field
						#here the expectation is that the query is a hash query.
#						if (hash?(query)); s2 = :hash; s3 = query; end
#					else
						#we should only 
#						if (int?(query)); s2 = :id; s3 = query; end
#					end
#				end

				#did we fail hard here?  Then drop to an error.
				#todo:  FIX the HTTP status code to be the correct one.
#				if (s2 == nil);	status 400;	return [];	end

				#set some SQL query parameters.
#				sstmt = table.columns_select + " WHERE #{s2} = \"#{s3}\""

#				rec_encode(db.fetch(sstmt).all).to_json
#			ensure
#				db.disconnect
#			end
#		end

		#register a path for table selection data
#		get (fullroute + '/:column/:selection') do |column, selection|
#			content_type :json
#			db = db_connect
#			begin
				#TODO:  Do a permissions check here.
				#permissions_check()

				#TODO:  Data sanitization
				#
				#

				#first check to see if we are seeking an id when it's prohibited.
#				if (table.properties[:use_hash] && ((column.strip == "id") || (column.strip[-3..-1] == ".id")))
					#TODO:  Fix this Error code?
#					return 400
#				end

				#next, check to see if our column is a foreign key
#				ftable = table.foreignkeys[column.to_sym]
#				if ((ftable != nil) && ($TABLES[ftable].properties[:use_hash]))
					#then rework the column to be that created in the hash substitution reference.
#					column = name.to_s + "_" + column + "_hash"
#				end

#				sstmt = table.columns_select + " WHERE #{column} = \"#{selection}\""

#				rec_encode(db.fetch(sstmt).all).to_json

#			ensure
#				db.disconnect
#			end
#		end
	end
end