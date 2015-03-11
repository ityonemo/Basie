#table_accessors.rb
#adds additional, common table accessor features to the table class.

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
