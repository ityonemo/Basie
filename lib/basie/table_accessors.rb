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

	def select_access_string(connector = :WHERE)
		raise SecurityError("no security set") unless Basie.access_control?
		#returns the select part that deal with access.
		access = (session[:login] ? session[:access] : @public_access)[:read][@name]
		#if we get nil, that means that access is denied.
		raise SecurityError("access denied") unless access
		#now we need to stitch the appropriate connector in here
		unless access == ""
			#useful/valid connectors are WHERE or AND, note MySQL is not case sensitive
			#so a lower-case one is just peachy keen.
			access.prepend("#{connector} ")
		end
		access
	end

	def access_filter_input_hash(content)
		raise SecurityError("no security set") unless Basie.access_control?
		#find the filter, this should be a lambda.
		accessfilter = (session[:login] ? session[:access] : @public_access)[:write][@name]
		#a nil result suggests that access is denied
		raise SecurityError("access denied") unless acessfilter
		#filter the content.
		accessfilter.call(content)
	end

	def entire_table(params={})
		#returns the entire table as a ruby object.
		#you can pass a list of tags to restore, or, all of them.

		#generate the suppression list by filtering out the restored tags (if applicable)

		@basie.connect do |db|
			#TODO:  Do a permissions check here.
			process db.fetch("SELECT #{csel} FROM #{@name} #{select_modifier_string} #{select_access_string}").all,
			  :preserve => true,
			  :suppresslist => @suppresslist,
			  :restore => params[:restore]
		end
	end

	def data_by_id(id, params={})
		res = nil
		#returns the table data by row id (primary or hash key)

		@basie.connect do |db|

			if (is_hash?(id))
				#double check to make sure our table supports hashes if we're sending a hash.
				raise(Basie::HashUnavailableError, "bad input") unless @settings[:use_hash]

				#create the (admittedly complicated) query
				res = db.fetch("SELECT #{csel} FROM #{@name} #{select_modifier_string} WHERE #{@name}.hash = '#{id}' #{select_access_string(:AND)}").first

				#a nil result means the hash didn't exist
				res == nil ? (raise Basie::NoHashError.new("hash not found")) : res
			elsif (Fixnum === id) || (id.to_i.to_s == id)

				#don't allow the use of ids if we're supposed to use hashes.
				raise(Basie::IdForbiddenError, "bad input")	if (@settings[:use_hash])

				#create the query.
				res = db.fetch("SELECT #{csel} FROM #{@name} #{select_modifier_string} WHERE #{@name}.id = '#{id}' #{select_access_string(:AND)}").first

				#a nil result means the id wasn't found.
				res == nil ? (raise Basie::NoIdError.new("id not found")) : res
			else
				raise(Basie::HashError, "malformed hash")
			end
			process res,
			  :suppresslist => @suppresslist,
			  :restore => params[:restore]
		end
	end

	def data_by_label(search, params={})
		raise Basie::LabelUnavailableError, "label not available for this table" unless @settings[:use_label]

		#returns table data by default label key.
		@basie.connect do |db|
			#generate the search column text

			cstmt = ""

			if @settings[:use_label].length == 1
				cstmt = @settings[:use_label][0]
			else
				cstmt = "CONCAT(" + @settings[:use_label].join(",") + ")"
			end

			process db.fetch("SELECT #{csel} from #{@name} #{select_modifier_string} WHERE #{cstmt} = '#{search}', #{select_access_string(:AND)}").all,
			  :suppresslist => @suppresslist,
			  :restore => params[:restore]
		end
	end

	def data_by_query(column, query, params={})
		#returns table data by general column query

		@basie.connect do |db|
			process db.fetch("SELECT #{csel} from #{@name} #{select_modifier_string} WHERE #{column} = '#{query}', #{select_access_string(:AND)}").all,
			    :suppresslist => @suppresslist,
			    :restore => params[:restore]
		end
	end

	def insert_data(data)
		#runs a basic insert.
		@basie.connect do |db|

			#data could be an array or a hash.
			case (data)
			when Array
				#if it's an array, it's more than one data hashes.
				data.each do |datum|
					datum = access_filter_input_hash(datum)
					id = db[@name].insert(datum)
					brandhash(id)
				end
			when Hash
				datum = access_filter_input_hash(datum)
				id = db[@name].insert(data)
				#brand the hash, since we have inserted new data
				brandhash(id)
			end
		end
	end

	def update_data(id, data)
		#a basic update should be a single item.
		#please remove the :id key when updating via id, and the :hash and :id keys when updating via identifier.

		#filter the input hash
		datum = access_filter_input_hash(datum)

		@basie.connect do |db|
			if (is_hash?(id))

				#hashes to hashes
				raise(Basie::HashUnavailableError, "bad input") unless @settings[:use_hash]

				#create the query
				res = db[@name].where(:hash => id).update(data)

				#double check to see if executed
				res == 0 ? raise(Basie::NoHashError, "hash doesn't exist") : res
			elsif (Fixnum === id) || (id.to_i.to_s == id)

				#idust to idust
				raise(Basie::IdForbiddenError, "bad input") if (@settings[:use_hash])

				#try and ind it and update it.
				res = db[@name].where(:id => id).update(data)

				#check to see if it executed, and raise the appropriate error if not.
				res == 0 ? raise(Basie::NoIdError, "id doesn't exist") : res
			else
				raise(Basie::HashError, "malformed hash")
			end
		end
	end
end
