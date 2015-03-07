#basie_test.rb
#unit testing for the basie object

require "test/unit"
require "rack/test"
require_relative '../lib/basie'

class BasieTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  #CONSTRUCTOR TESTS

  def test_initialization_null
    assert_raise (ArgumentError) {bs = Basie.new}
  end

  def test_initialization_defaults
    bs = Basie.new :name => "testdb"
    assert_equal(bs.login, "www-data", "default login incorrect")
    assert_equal(bs.pass, "",  "default password incorrect")
    assert_equal(bs.host, "localhost",  "default host incorrect")
    assert_equal(bs.name, "testdb",  "default name incorrect")
  end

  def test_initialization_custom
    bs = Basie.new :login => "login_test", :pass => "pass_test", :host => "host_test", :name => "testdb"
    assert_equal(bs.login, "login_test", "custom login incorrect")
    assert_equal(bs.pass, "pass_test",  "custom password incorrect")
    assert_equal(bs.host, "host_test",  "custom host incorrect")
    assert_equal(bs.name, "testdb",  "custom name incorrect")
  end

  #CONNECTION TESTS

  def test_connection
    bs = Basie.new :name => "testdb"
    bs.connect do
      #specific setup:  create a blank table, nothing but a primary key.
      bs.db.create_table :testtable do
        primary_key   :id
      end

      #check to see if the table exists.
      assert(bs.db.table_exists?(:testtable), "table not created in a test connection")

      #specific teardown:  take down the table and leave a blank testdb.
      bs.db.drop_table :testtable
    end
  end

  def test_db_ops
    #test some simple database operations
    bs = Basie.new :name => "testdb"
    #create a blank table, with a primary key and a single element.
    bs.connect do
      bs.db << 'CREATE TABLE testtable (testcolumn char(64))'
      bs.db[:testtable].insert({:testcolumn => "test test"})
      res = bs.db[:testtable].first

      assert_equal(res[:testcolumn], "test test", "retrieved data from test brackets not correct")

      bs.db.drop_table :testtable
    end
  end
end