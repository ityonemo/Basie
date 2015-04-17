#test_databases.rb

#common creation schemes for test databases.

#forward the existence of the Basie class.
class Basie; end

#monkey-patch the MockResponse Class to give a "success?" readout which is agnostic to all forms of HTTP success (not just OK)
class Rack::MockResponse
  def success?
    @status >= 200 && @status < 300
  end
end

#declare a global singleton Basie object for convenience.
$BS = Object.new

#reflective create command.  Takes an array of symbols and makes tables.
def create(tablename)
  #allow us to pass either a single symbol or an array of symbols.
  if Symbol === tablename
    tablename = [tablename]
  end

  tablename.each do |table|
    #standard creation protocol.
    $BS.create table

    #here is the reflective magic.  Defined below in this list is this thingy.
    $BS.connect {|db| eval "data_#{table} db"}
  end

  $BS
end

def data_simpletest(db)
  db[:simpletest].insert(:test => "one")
  db[:simpletest].insert(:test => "two")
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

#nothing.  This test just tests html input system
def data_complextest(db); end

def data_lefttest(db)
  db[:lefttest].insert(:leftcontent => "left 1", :right => 1)
  db[:lefttest].insert(:leftcontent => "left 2", :right => 2)
end

def data_righttest(db)
  db[:righttest].insert(:rightcontent => "right 1")
  db[:righttest].insert(:rightcontent => "right 2")
end

def data_lefttest_nolink(db)
  db[:lefttest_nolink].insert(:leftcontent => "left 1", :right => 1)
  db[:lefttest_nolink].insert(:leftcontent => "left 2", :right => 2)
end

def data_righttest_hash(db)
  ids = []

  ids.push db[:righttest_hash].insert(:rightcontent => "right 1")
  ids.push db[:righttest_hash].insert(:rightcontent => "right 2")

  ids.each{|i| $BS.tables[:righttest_hash].brandhash(i)}
end

def data_lefttest_hash(db)
  db[:lefttest_hash].insert(:leftcontent => "left 1", :right => 1)
  db[:lefttest_hash].insert(:leftcontent => "left 2", :right => 2)
end

def data_righttest_label(db)
  ids = []

  ids.push db[:righttest_label].insert(:rightcontent => "nina")
  ids.push db[:righttest_label].insert(:rightcontent => "nana")

  ids.each{|i| $BS.tables[:righttest_label].brandhash(i)}
end

def data_lefttest_label(db)
  db[:lefttest_label].insert(:leftcontent => "left 1", :right => 1)
  db[:lefttest_label].insert(:leftcontent => "left 2", :right => 2)
end

#nothing.  This just tests a bad label entry.
def data_righttest_label_bad(db); end

def data_usertest(db)
  db[:usertest].insert(:login => "user 1", :passhash => Basie::UserInterface.encrypt("user 1 pass", "user 1").to_s)
  db[:usertest].insert(:login => "user 2", :passhash => Basie::UserInterface.encrypt("user 2 pass", "user 2").to_s)
end

def data_usertest_email(db)
  db[:usertest_email].insert(:email => "user1@gmail.com", :passhash => Basie::UserInterface.encrypt("user 1 pass", "user1@gmail.com").to_s)
  db[:usertest_email].insert(:email => "user2@gmail.com", :passhash => Basie::UserInterface.encrypt("user 2 pass", "user2@gmail.com").to_s)
end

#nothing.
def data_suppresstest(db)
  db[:suppresstest].insert(:test => "test 1", :test2 => "test 2", :test3 => "test 3", :test4 => "test 4")
  $BS.tables[:suppresstest].brandhash(1)
end