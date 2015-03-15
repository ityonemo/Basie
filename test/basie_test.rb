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
    assert_equal "www-data",    bs.login,   "default login incorrect"
    assert_equal "",            bs.pass,    "default password incorrect"
    assert_equal "localhost",   bs.host,    "default host incorrect"
    assert_equal "testdb",      bs.name,    "default name incorrect"
  end

  def test_initialization_custom
    bs = Basie.new :login => "login_test", :pass => "pass_test", :host => "host_test", :name => "testdb"
    assert_equal  "login_test", bs.login,  "custom login incorrect"
    assert_equal  "pass_test",  bs.pass,   "custom password incorrect"
    assert_equal  "host_test",  bs.host,   "custom host incorrect"
    assert_equal  "testdb",     bs.name,   "custom name incorrect"
  end

  #CONNECTION TESTS

  def test_connection
    bs = Basie.new :name => "testdb"
    bs.connect do
      bs.db.drop_table? :testtable
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
      bs.db.drop_table? :testtable
      bs.db << 'CREATE TABLE testtable (testcolumn char(64))'
      bs.db[:testtable].insert({:testcolumn => "test test"})
      res = bs.db[:testtable].first

      assert_equal "test test", res[:testcolumn], "retrieved data from test brackets not correct"

      bs.db.drop_table :testtable
    end
  end

  #TEST INTERFACE INITIALIZATION
  def test_default_interfaces
    Basie.activate :CSV
    Basie.activate :HTML
    Basie.activate :JSON

    assert_equal 3, Basie.interfaces.length, "failed to find a default interface"
    Basie.purge_interfaces
  end

  def test_double_interfacing
    #the interface list should reject an attempt to duplicate an interface.
    Basie.activate :CSV
    Basie.activate :CSV

    assert_equal 1, Basie.interfaces.length, "failed to not instantiate duplicate interfaces"
    Basie.purge_interfaces
  end

  def test_try_to_interpret_nothing
    assert_raise(ArgumentError){Basie.activate :notaclass}
  end

  def test_try_to_interpret_bad_class
    assert_raise(ArgumentError){Basie.activate :String}
  end

  def test_by_class
    Basie.activate Basie::HTMLInterface

    assert_equal 1, Basie.interfaces.length, "failed to instantiate an interface by class"
    Basie.purge_interfaces
  end

end