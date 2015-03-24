#table_accessors.rb
#adds additional, common table accessor features to the table class.
#segregated from the main Basie::Table object for code organization purposes.

require_relative 'basie_errors'

#forward the existence of the Basie class
class Basie; end

class Basie::Table 

	def process(r)
		case r 
		when Array
			r.map{|v| process(v)}
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
		end
	end

	def csel
		#returns a select string that corresponds to an 'adjusted' select statement
		#two things must be done.  
		#1.		primary_key must be eliminated if use_hash is activated.
		#2.		foreign_key must be substituted if the foreign use_hash is activated.

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

	def select_modifier_strings
		#joins and selects and as that substitutes in the table.
		join = @foreignkeys.keys.reject{|k| !@basie.tables[@foreignkeys[k]].settings[:use_hash]}
			.map do |k|
				fname = @foreignkeys[k] 
				"LEFT JOIN #{@name}_#{k}_lookup ON #{@name}.#{k}=#{@name}_#{k}_lookup.id"
			end.join(' ')
		join
	end
	private :select_modifier_strings

	def entire_table
		#returns the entire table as a ruby object.
		@basie.connect do |db|
			#TODO:  Do a permissions check here.

			join = select_modifier_strings
			select = "SELECT #{csel} FROM #{@name} #{join}"
			process(db.fetch(select).all)
		end
	end

	def data_by_id(id)
		res = nil
		#returns the table data by row id (primary or hash key)

		@basie.connect do |db|
			case id.to_i		#use the to_i function to assess if it's a hash or not.			
			when 0
				unless (is_hash?(id) && @settings[:use_hash])
					raise(Basie::HashError, "bad input")
				end
				res = db.fetch("SELECT #{csel} FROM #{@name} WHERE hash = '#{id}'").first
				res == nil ? (raise Basie::NoHashError.new("id not found")) : res
			else
				res = db.fetch("SELECT #{csel} FROM #{@name} WHERE id = '#{id}'").first
				res == nil ? (raise Basie::NoIdError.new("hash not found")) : res
			end
		end
	end

	def data_by_search(search)
		#returns table data by default search key.
		@basie.connect do |db|
			#generate the search column text
			searchcol = ""
			db.fetch("SELECT #{csel} from #{@name} WHERE #{searchcol} = '#{search}'").first
		end
	end

	def data_by_query(column, query)
		#returns table data by general column query
		@basie.connect do |db|
			db.fetch("SELECT #{csel} from #{@name} WHERE #{column} = '#{query}'").first
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

	def update_data(identifier, data)
		#a basic update should be a single item.
		#please remove the :id key when updating via id, and the :hash and :id keys when updating via identifier.
		@basie.connect do |db|
			case identifier.to_i
			when 0 #should be a hash

				unless is_hash?(identifier)
					raise(Basie::HashError, "bad input")
				end

				res = db[@name].where(:hash => identifier).update(data)
				res == 0 ? raise(Basie::NoHashError, "hash doesn't exist") : res
			else  #should be an id number.
				res = db[@name].where(:id => identifier).update(data)
				res == 0 ? raise(Basie::NoIdError, "id doesn't exist") : res
			end
		end
	end
end
