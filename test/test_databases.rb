#test_databases.rb

#common creation schemes for test databases.

class Basie; end

$BS = {}

def create(tablename)
  $BS = Basie.new :name => "testdb"

  $BS.connect do |db|
    db.drop_table?(tablename)
  end

  $BS.create tablename

  eval("data_#{tablename}")

  $BS
end

def destroy(tablename)
  $BS.connect do |db|
    db.drop_table?(tablename)
  end
end

def data_simpletest
  $BS.connect do |db|
    #insert some sample data here.
    db[:simpletest].insert(:test => "one")
    db[:simpletest].insert(:test => "two")
  end
end

def data_urltest
  $BS.connect do |db|
    #insert some sample data here.
    db[:urltest].insert(:test => "http://test.com/testone")
    db[:urltest].insert(:test => "http://test.com/testtwo")
  end
end

def data_emailtest
  $BS.connect do |db|
    #insert some sample data here.
    db[:emailtest].insert(:test => "one@test.com")
    db[:emailtest].insert(:test => "two@test.com")
  end
end

def data_teltest
  #pre-prepping
  $BS.connect do |db|
    #insert some sample data here.
    db[:teltest].insert(:test => "111-111-1111")
    db[:teltest].insert(:test => "222-222-2222")
  end
end

def data_hashtest
  ids = []

  $BS.connect do |db|
    ids.push db[:hashtest].insert(:content => "test 1")
    ids.push db[:hashtest].insert(:content => "test 2")
    ids.push db[:hashtest].insert(:content => "test 3")

    ids.each{|i| $BS.tables[:hashtest].brandhash(i)}
  end
end