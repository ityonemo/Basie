#table_accessors.rb
#adds additional, common table accessor features to the table class.
#segregated from the main Basie::Table object for code organization purposes.

require_relative 'basie_errors'

#forward the existence of the Basie class
class Basie; end

class Basie::Table

	def process(r, params = {})
		#make the suppress list
		params[:suppresslist] ||= []

		#adjust the suppress list based on any "restores"
		_suppresslist = case params[:restore]
		when nil
			params[:suppresslist]
		when :all
			[]
		when Symbol
			#a single symbol, not ":all"
			params[:suppresslist].reject{|s| s == params[:restore]}
		when Array
			#hopefully, an array of symbols (but it's not necessary, just other elements won't work)
			params[:suppresslist].reject{|s| params[:restore].include? s}
		else
			raise ArgumentError, "suppresslist must be nil, :all, a symbol, or an array of symbols"
		end

		case r
		when Array
			case r.length
			when 0
				nil
			when 1
				if params[:preserve]
					[process(r[0], params)]
				else
					#unpack the array
					process(r[0], params)
				end
			else
				r.map{|v| process(v, params)}
			end
		when Hash
			#then swap out the subscripted key for the normal key.
			temp = {}
			r.each_key do |k|
				#just skip it if we aren't supposed to have it.
				next if _suppresslist.include? k
				#we might have to do a conversion if it's coming from a view.
				ks = k.to_s
				if ks[-1] == "_"
					temp[ks[0...-1].to_sym] = r[k]
				else
					temp[k] = r[k]
				end
			end
			temp
		else
			nil
		end
	end

	def csel
		#returns a select string that corresponds to an 'adjusted' select statement
		#1.		primary_key must be eliminated if use_hash is activated.
		#primary key stuff

		columns.keys.map do |k|
			if (@foreignkeys.has_key?(k) && @basie.tables[@foreignkeys[k]].settings[:use_hash])
				"#{@name}_#{k}_lookup.hash AS #{k}_"
			else
				"#{@name}.#{k}"
			end
		end.join(", ")
	end

	def select_modifier_string
		#joins and selects and as that substitutes in the table.
		join = @foreignkeys.keys.reject{|k| !@basie.tables[@foreignkeys[k]].settings[:use_hash]}
			.map do |k|
				fname = @foreignkeys[k]
				"LEFT JOIN #{@name}_#{k}_lookup ON #{@name}.#{k}=#{@name}_#{k}_lookup.id"
			end.join(' ')
		join
	end
	private :select_modifier_string

	def select_access_string(session, connector = :WHERE)
		raise SecurityError, "no security set" unless @basie.access_control?

		#returns the select part that deal with access.
		access = (session[:login] ? session[:access][@name] : @public_access)[:read]

		#if we get nil, that means that access is denied.
		return nil unless access

		#now we need to stitch the appropriate connector in here
		unless access == ""
			#useful/valid connectors are WHERE or AND, note MySQL is not case sensitive
			#so a lower-case one is just peachy keen.
			access.prepend("#{connector} ")
		end
		access
	end

	def access_filter_input_hash(session, content)
		raise SecurityError, "no security set" unless @basie.access_control?

		#find the filter, this should be a lambda definition.
		accessfilter = (session[:login] ? session[:access][@name] : @public_access)[:write]

		#a nil result suggests that access is denied
		return nil unless accessfilter
		#compile the access filter string into an executeable, then filter the content

		eval("lambda" + accessfilter).call(content)
	end

	def entire_table(params={})
		#returns the entire table as a ruby object.

		#check to see if access is disallowed by the security parameters
		accessfilter = params[:override_security] ? "" : select_access_string(params[:session])
		raise SecurityError, "access disallowed" unless accessfilter

		@basie.connect do |db|
			process db.fetch("SELECT #{csel} FROM #{@name} #{select_modifier_string} #{accessfilter}").all,
				:preserve => true,
				:suppresslist => @suppresslist,
				:restore => params[:restore]
		end
	end

	def data_by_id(id, params={})
		#returns the table data by row id (primary or hash key)

		#check to see if access is disallowed by the security parameters
		accessfilter = params[:override_security] ? "" : select_access_string(params[:session], :AND)
		raise SecurityError, "access disallowed" unless accessfilter

		#an object to store the result
		res = nil

		if (is_hash?(id))
			#the query looks like a hash query. double check to make sure our table
			#supports hashes since we're sending a hash.
			raise Basie::HashUnavailableError, "bad input" unless @settings[:use_hash]

			#create the query
			q = "SELECT #{csel} FROM #{@name} #{select_modifier_string} WHERE #{@name}.hash = '#{id}' #{accessfilter}"

			#connect and pull the results of the query
			res = @basie.connect {|db| db.fetch(q).first}

			#a nil result means the hash didn't exist
			raise Basie::NoHashError, "hash not found" unless res

		elsif (Fixnum === id) || (id.to_i.to_s == id)

			#don't allow the use of ids if we're supposed to use hashes.
			raise Basie::IdForbiddenError, "bad input" if @settings[:use_hash]

			#create the query.
			q = "SELECT #{csel} FROM #{@name} #{select_modifier_string} WHERE #{@name}.id = '#{id}' #{accessfilter}"

			#connect and pull the results of the query
			res = @basie.connect{|db| db.fetch(q).first}

			#a nil result means the id wasn't found.
			raise Basie::NoIdError, "id not found" unless res
		else
			raise Basie::HashError, "malformed hash"
		end

		#make it look nice and return the result.
		process res, :suppresslist => @suppresslist, :restore => params[:restore]
	end

	def data_by_label(search, params={})
		#check to see if this table has labels available.
		raise Basie::LabelUnavailableError, "label not available for this table" unless @settings[:use_label]

		#check to see if access is disallowed by the security parameters
		accessfilter = params[:override_security] ? "" : select_access_string(params[:session], :AND)
		raise SecurityError, "access disallowed" unless accessfilter

		#generate the search column text
		cstmt = (@settings[:use_label].length == 1) ? @settings[:use_label][0] : "CONCAT(" + @settings[:use_label].join(",") + ")"

		#generate the query text from the search statement and the other parameters.
		q = "SELECT #{csel} from #{@name} #{select_modifier_string} WHERE #{cstmt} = '#{search}' #{accessfilter}"

		#connect to the database and then process the data.
		process @basie.connect{|db| db.fetch(q).all},
				:suppresslist => @suppresslist,
			  :restore => params[:restore]
	end

	def data_by_query(column, query, params={})
		#returns table data by general column query

		#check to see if access is disallowed by the security parameters.
		accessfilter = params[:override_security] ? "" : select_access_string(params[:session], :AND)
		raise SecurityError, "access disallowed" unless accessfilter

		#generate the search column text
		q = "SELECT #{csel} from #{@name} #{select_modifier_string} WHERE #{column} = '#{query}' #{accessfilter}"

		#connect to the database and process the data.
		process @basie.connect {|db| db.fetch(q).all},
			    :suppresslist => @suppresslist,
			    :restore => params[:restore]
	end

	def insert_data(data, params = {})
		#runs a basic insert on variadic (Array/Hash) data
		#in the case of an array, it should be a series of input-ok hashes
		#in the case of a hash, it should be key/value pairs that correspond to
		#column/data.
		case (data)
		when Array
			#if it's an array, it's more than one data hashes.
			@basie.connect do |db|
				data.each do |datum|
					#filter our data based on security preferences
					datum = params[:override_securty] ? datum : access_filter_input_hash(params[:session], datum)

					raise SecurityError, "access disallowed" unless datum

					datum.reject!{|col, val| c = col.to_sym; (!@columns.has_key?(c) || c == :id || c == :hash)}

					#actually insert the data, then brand the data if necessary
					id = db[@name].insert(datum)
					brandhash(id)
				end
			end
		when Hash
			basie.connect do |db|
				#filter our data based on security preferences

				data = params[:override_security] ? data : access_filter_input_hash(params[:session], data)
				raise SecurityError, "access disallowed" unless data

				data.reject!{|col, val| c = col.to_sym; (!@columns.has_key?(c) || c == :id || c == :hash)}

				#actually insert the data, then brand the data, if necessary
				id = db[@name].insert(data)
				brandhash(id)
			end
		else raise ArgumentError, "insert_data must take an Array or Hash"
		end
	end

	def update_data(id, data, params = {})
		#a basic update should be a single item.

		#create a placeholder variable for the result.
		res = nil

		#filter the input hash, and throw an error if write is disallowed.
		data = params[:override_security] ? data : access_filter_input_hash(params[:session], data)
		raise SecurityError, "access disallowed" unless data

		data.reject!{|col, val| c = col.to_sym; (!@columns.has_key?(c) || c == :id || c == :hash)}

		if (is_hash?(id))
			#hashes to hashes
			raise Basie::HashUnavailableError, "bad input" unless @settings[:use_hash]

			#create and execute the updating query
			res = @basie.connect {|db| db[@name].where(:hash => id).update(data)}

			#double check to see if executed.  In this case, res returns # of rows changed
			raise Basie::NoHashError, "hash doesn't exist" unless res == 1
		elsif (Fixnum === id) || (id.to_i.to_s == id)
			#idust to idust
			raise Basie::IdForbiddenError, "bad input" if @settings[:use_hash]

			#try and ind it and update it.
			res = @basie.connect {|db| db[@name].where(:id => id).update(data)}

			#check to see if it executed, and raise the appropriate error if not.
			#in this case, res returns # of rows changed.
			raise Basie::NoIdError, "id doesn't exist" unless res == 1
		else
			raise Basie::HashError, "malformed hash"
		end
		res
	end
end
