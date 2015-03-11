#test_databases.rb

#common creation schemes for test databases.

class Basie; end

def create_simpletest
  bs = Basie.new :name => "testdb"

  bs.connect do |db|
  	db.drop_table?(:simpletest)
  end

  bs.create :simpletest

  #pre-prepping
  bs.connect do |db|
  	#insert some sample data here.
  	db[:simpletest].insert(:test => "one")
  	db[:simpletest].insert(:test => "two")
  end
end