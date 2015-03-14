#test_databases.rb

#common creation schemes for test databases.

class Basie; end

$BS = {}

def create(tablename)
  $BS = Basie.new :name => "testdb"

  if Symbol === tablename
    tablename = [tablename]
  end

  tablename.each do |table|
    $BS.connect{|db| db.drop_table?(table) }
    $BS.create table
    $BS.connect {|db| eval "data_#{table} db"}
  end

  $BS
end

def destroy(tablename)
  if Symbol === tablename
    tablename = [tablename]
  end

  $BS.connect do |db|
    tablename.each do |table|
      db.drop_table?(table)
    end
  end
end

def data_simpletest(db)
  db[:simpletest].insert(:test => "one")
  db[:simpletest].insert(:test => "two")
end

def data_urltest (db)
  db[:urltest].insert(:test => "http://test.com/testone")
  db[:urltest].insert(:test => "http://test.com/testtwo")
end

def data_emailtest (db)
  db[:emailtest].insert(:test => "one@test.com")
  db[:emailtest].insert(:test => "two@test.com")
end

def data_teltest (db)
  db[:teltest].insert(:test => "111-111-1111")
  db[:teltest].insert(:test => "222-222-2222")
end

def data_hashtest(db)
  ids = []

  ids.push db[:hashtest].insert(:content => "test 1")
  ids.push db[:hashtest].insert(:content => "test 2")
  ids.push db[:hashtest].insert(:content => "test 3")

  ids.each{|i| $BS.tables[:hashtest].brandhash(i)}
end

def data_complextest(db)
  #nothing.  This test just tests html input system
end

def data_foreign_left(db)
end

def data_foreign_right(db)
end