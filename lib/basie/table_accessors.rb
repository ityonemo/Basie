#table_accessors.rb
#adds additional, common table accessor features to the table class.
#segregated from the main Basie::Table object for code organization purposes.

require_relative 'basie_errors'

#forward the existence of the Basie class
class Basie; end

class Basie::Table 

	def process(r, preserve = false)
		case r 
		when Array
			case r.length
			when 0
				nil
			when 1
				if preserve
					[process(r[0])]
				else
					#unpack the array
					process(r[0])
				end
			else
				r.map{|v| process(v)}
			end
		when Hash
			#then swap out the subscripted key for the normal key.
			temp = {}
			r.each_key do |k|
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

		if @settings[:use_hash]
			c = columns
		else
			c = columns(true)
		end

		c.keys.map do |k|
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

	def entire_table
		#returns the entire table as a ruby object.
		@basie.connect do |db|
			#TODO:  Do a permissions check here.
			process(db.fetch("SELECT #{csel} FROM #{@name} #{select_modifier_string}").all, true)
		end
	end

	def data_by_id(id)
		res = nil
		#returns the table data by row id (primary or hash key)

		@basie.connect do |db|

			if (is_hash?(id))
				unless settings[:use_hash]
					raise(Basie::HashUnavailableError, "bad input")
				end
				res = db.fetch("SELECT #{csel} FROM #{@name} #{select_modifier_string} WHERE #{@name}.hash = '#{id}'").first
				res == nil ? (raise Basie::NoHashError.new("id not found")) : res
			elsif (Fixnum === id) || (id.to_i.to_s == id)
				if (@settings[:use_hash])
					raise(Basie::IdForbiddenError, "bad input")
				end
				res = db.fetch("SELECT #{csel} FROM #{@name} #{select_modifier_string} WHERE #{@name}.id = '#{id}'").first
				res == nil ? (raise Basie::NoIdError.new("hash not found")) : res
			else
				raise(Basie::HashError, "malformed hash")
			end
			process res
		end
	end

	def data_by_label(search)
		unless @settings[:use_label]
			raise Basie::LabelUnavailableError, "label not available for this table"
		end
		#returns table data by default label key.
		@basie.connect do |db|
			#generate the search column text

			cstmt = ""

			if @settings[:use_label].length == 1
				cstmt = @settings[:use_label][0]
			else
				cstmt = "CONCAT(" + @settings[:use_label].join(",") + ")"
			end

			process(db.fetch("SELECT #{csel} from #{@name} #{select_modifier_string} WHERE #{cstmt} = '#{search}'").all)
		end
	end

	def data_by_query(column, query)
		#returns table data by general column query
		@basie.connect do |db|
			process(db.fetch("SELECT #{csel} from #{@name} #{select_modifier_string} WHERE #{column} = '#{query}'").all)
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
				unless settings[:use_hash]
					raise(Basie::HashUnavailableError, "bad input")
				end
				res = db[@name].where(:hash => id).update(data)
				res == 0 ? raise(Basie::NoHashError, "hash doesn't exist") : res
			elsif (Fixnum === id) || (id.to_i.to_s == id)
				if (@settings[:use_hash])
					raise(Basie::IdForbiddenError, "bad input")
				end

				res = db[@name].where(:id => id).update(data)
				res == 0 ? raise(Basie::NoIdError, "id doesn't exist") : res
			else
				raise(Basie::HashError, "malformed hash")
			end
		end
	end
end