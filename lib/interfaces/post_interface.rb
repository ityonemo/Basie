require_relative "base_interface"

#POST intrepreter, creates a route for accepting POST instructions.
class Basie::POSTInterface < Basie::Interface

	def initialize(params={})
		@root = "/db"

		super(params)
	end

	def setup_paths(table)

		tableroot = "#{@root}/#{table.name}"

		app.post(tableroot) do 
			
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

			#toss out parameters that aren't the ones we care about.  Also drop out :id and :hash parameters in case of adversarial attempts\
			p = params.reject{|col, val| c = col.to_sym; (!table.columns.has_key?(c) || c == :id || c == :hash)}

			table.insert_data(p)
			201
		end

		app.post(tableroot + "/:id") do |id|
			#toss out parameters that aren't the ones we care about. Also drop out :id and :hash parameters in case of adversarial attempts
			p = params.reject{|col, val| c = col.to_sym; (!table.columns.has_key?(c) || c == :id || c == :hash)}

			begin
				table.update_data(id, p)
				201
			rescue ArgumentError
				400
			rescue Basie::NoEntryError
				404
			end
		end

	end
end