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
end
