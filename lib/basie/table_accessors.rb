#table_accessors.rb
#adds additional, common table accessor features to the table class.
#segregated from the main Basie::Table object for code organization purposes.

require_relative 'basie_errors'

#forward the existence of the Basie class
class Basie; end

class Basie::Table 

	def process(r, params = {})
		params[:suppresslist] ||= []
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
				next if params[:suppresslist].include? k
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

	def entire_table(params={})
		#returns the entire table as a ruby object.

		#generate the suppression list by filtering out the restored tags (if applicable)
		_suppresslist = params[:restore] ? @suppresslist.reject{|s| params[:restore].include? s} : @suppresslist

		@basie.connect do |db|
			#TODO:  Do a permissions check here.
			process db.fetch("SELECT #{csel} FROM #{@name} #{select_modifier_string}").all, :preserve => true, :suppresslist => _suppresslist
		end
	end

	def data_by_id(id, params={})
		res = nil
		#returns the table data by row id (primary or hash key)

		#generate the suppression list by filtering out the restored tags (if applicable)
		_suppresslist = params[:restore] ? @suppresslist.reject{|s| params[:restore].include? s} : @suppresslist

		@basie.connect do |db|

			if (is_hash?(id))
				#double check to make sure our table supports hashes if we're sending a hash.
				raise(Basie::HashUnavailableError, "bad input") unless @settings[:use_hash]

				#create the (admittedly complicated) query
				res = db.fetch("SELECT #{csel} FROM #{@name} #{select_modifier_string} WHERE #{@name}.hash = '#{id}'").first

				#a nil result means the hash didn't exist
				res == nil ? (raise Basie::NoHashError.new("hash not found")) : res
			elsif (Fixnum === id) || (id.to_i.to_s == id)

				#don't allow the use of ids if we're supposed to use hashes.
				raise(Basie::IdForbiddenError, "bad input")	if (@settings[:use_hash])

				#create the query.
				res = db.fetch("SELECT #{csel} FROM #{@name} #{select_modifier_string} WHERE #{@name}.id = '#{id}'").first

				#a nil result means the id wasn't found.
				res == nil ? (raise Basie::NoIdError.new("id not found")) : res
			else
				raise(Basie::HashError, "malformed hash")
			end
			process res, :suppresslist => _suppresslist
		end
	end

	def data_by_label(search, params={})
		raise Basie::LabelUnavailableError, "label not available for this table" unless @settings[:use_label]

		#generate the suppression list by filtering out the restored tags (if applicable)
		_suppresslist = params[:restore] ? @suppresslist.reject{|s| params[:restore].include? s} : @suppresslist

		#returns table data by default label key.
		@basie.connect do |db|
			#generate the search column text

			cstmt = ""

			if @settings[:use_label].length == 1
				cstmt = @settings[:use_label][0]
			else
				cstmt = "CONCAT(" + @settings[:use_label].join(",") + ")"
			end

			process db.fetch("SELECT #{csel} from #{@name} #{select_modifier_string} WHERE #{cstmt} = '#{search}'").all, :suppresslist => _suppresslist
		end
	end

	def data_by_query(column, query, params={})
		#returns table data by general column query

		#generate the suppression list by filtering out the restored tags (if applicable)
		_suppresslist = params[:restore] ? @suppresslist.reject{|s| params[:restore].include? s} : @suppresslist

		@basie.connect do |db|
			process db.fetch("SELECT #{csel} from #{@name} #{select_modifier_string} WHERE #{column} = '#{query}'").all, :suppresslist => _suppresslist
		end
	end

	def insert_data(data)
		#runs a basic insert.
		@basie.connect do |db|

			#data could be an array or a hash.
			case (data)
			when Array
				data.each do |datum|
					id = db[@name].insert(datum)
					brandhash(id)
				end
			when Hash
				id = db[@name].insert(data)
				#brand the hash, since we have inserted new data
				brandhash(id)
			end
		end
	end

	def update_data(id, data)
		#a basic update should be a single item.
		#please remove the :id key when updating via id, and the :hash and :id keys when updating via identifier.
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
