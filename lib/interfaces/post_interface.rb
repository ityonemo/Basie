require_relative "base_interface"

#POST intrepreter, creates a route for accepting POST instructions.
class Basie::POSTInterface < Basie::Interface

	def setup_paths(table)

		app.post(data) do 
			
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
			params.reject!{|col, val| !table.columns.has_key?(col)}

			table.insert_data(params)

			if params[:redirect] == nil
				#if we haven't specified a redirect, redirect to the database object created.
				redirect "/db/#{name}/#{hash}"
			else
				redirect params[:redirect]
			end
		end
	end
end