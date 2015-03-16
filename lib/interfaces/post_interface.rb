require_relative "base_interface"

#POST intrepreter, creates a route for accepting POST instructions.
class Basie::POSTInterface < Basie::Interface

	def initialize(params={})
		@route = "/db"

		super(params)
	end

	def setup_paths(table)

		fullpath = "#{@route}/#{table.name}"

		app.post(fullpath) do 
			
			#TODO:  Do a permissions check here.
			#permissions_check()

			#TODO:  Data sanitization
			#

=begin
			#look for foreign_keys or searchables in table spec, then search these by hash.
			params.each do |column, value|
				#  NB Ruby 2.2 now garbage collects symbols so a malicious actor can't overload
				#     the system by repeatedly allocating strange symbols to the VM.
				searchcol = nil
				searchtable = nil

				if table.foreignkeys.has_key?(column.to_sym)		#is it foreign?
					searchtable = table.foreignkeys[column.to_sym]
					if hash?(value)					#check if it looks like a hash.
						searchcol = :hash
					else
						searchcol = $TABLES[searchtable].properties[:searchable] 	#assign the search column here.
					end
				end
			end
=end

			#toss out parameters that aren't the ones we care about.
			p = params.reject{|col, val| !table.columns.has_key?(col.to_sym)}

			table.insert_data(p)

			"ok"
		end

		app.post(fullpath + "/:id") do |id|
			#toss out parameters that aren't the ones we care about.

			p = params.reject{|col, val| !table.columns.has_key?(col.to_sym)}

			table.update_data(id, p)

			"ok"
		end

	end
end