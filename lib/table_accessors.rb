#table_accessors.rb
#adds additional, common table accessor features to the table class.
#segregated from the main Basie::Table object for code organization purposes.

#forward the existence of the Basie class
class Basie; end

class Basie::Table 

	def csel
		#returns a select string that corresponds to an 'adjusted' select statement
		#two things must be done.  
		#1.		primary_key must be eliminated if use_hash is activated.
		#2.		foreign_key must be substituted if the foreign use_hash is activated.

		#primary key stuff
		if settings[:use_hash]
			columns.keys.map{|k| k.to_s}.join(", ")
		else
			"*"
		end
	end

	def entire_table
		#returns the entire table as a ruby object.
		@basie.connect do |db|
			#TODO:  Do a permissions check here.

			#TODO:  Repair this so that it deals with special situations, foreign keys, etc.
			db.fetch("SELECT #{csel} FROM #{@name}").all
		end
	end

	def data_by_id(id)
		#returns the table data by row id (primary or hash key)
		@basie.connect do |db|
			case id.to_i		#use the to_i function to assess if it's a hash or not.			
			when 0
				db.fetch("SELECT #{csel} from #{@name} WHERE hash = '#{id}'").first
			else
				db.fetch("SELECT #{csel} FROM #{@name} WHERE id = '#{id}'").first
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
		basie.connect do |db|
			case identifier
			when Integer  #should be an id number.
				db[@name].where(:id => identifier).update(data)
			when String #should be a hash
				db[@name].where(:hash => identifier).update(data)
			end
		end
	end
end
