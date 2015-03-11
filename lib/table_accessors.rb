#table_accessors.rb
#adds additional, common table accessor features to the table class.
#segregated from the main Basie::Table object for code organization purposes.

#forward the existence of the Basie class

class Basie; end

class Basie::Table 
	def entire_table
		#returns the entire table as a ruby object.

		@basie.connect do |db|
			#TODO:  Do a permissions check here.

			#TODO:  Repair this so that it deals with special situations, foreign keys, etc.
			db.fetch("SELECT * FROM #{@name}").all
		end
	end

	def table_by_id(id)
		#returns the table data by row id (primary key)
		@basie.connect do |db|
			db.fetch("SELECT * FROM #{@name} WHERE id = '#{id}'").first
		end
	end

	def table_by_hash(hash)
		#returns the table data by hash (secondary key)
		@basie.connect do |db|
			db.fetch("SELECT * from #{@name} WHERE hash = '#{hash}'").first
		end
	end
end
