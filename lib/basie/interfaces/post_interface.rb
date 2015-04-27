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
			#toss out parameters that aren't the ones we care about.  Also drop out :id and :hash parameters in case of adversarial attempts

			p = params.reject{|col, val| c = col.to_sym; (!table.columns.has_key?(c) || c == :id || c == :hash)}

			begin
				table.insert_data(p, :session => session)
				201
			rescue SecurityError
				403
			end
		end

		app.post(tableroot + "/:id") do |id|
			#toss out parameters that aren't the ones we care about. Also drop out :id and :hash parameters in case of adversarial attempts

			p = params.reject{|col, val| c = col.to_sym; (!table.columns.has_key?(c) || c == :id || c == :hash)}

			begin

				table.update_data(id, p, :session => session)

				201
			rescue SecurityError

				403
			rescue ArgumentError
				400
			rescue Basie::NoHashError, Basie::NoIdError
				404
			rescue => e
				puts e.inspect
				throw
			end
		end

	end
end
