#table_test.rb
#unit testing for the Basie::Table object

require "test/unit"
require "rack/test"
require_relative '../lib/basie'

class TableTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  #TEST CREATING A TABLE.  These methods should emanate from the basie object.

  def test_create_table_no_symbol_argument
    bs = Basie.new :name => "testdb"
    #should not create a blank table
    assert_raise(ArgumentError){bs.create "wrong input"}
  end

  def test_create_table_no_definition_file
    bs = Basie.new :name => "testdb"
    #create a blank table, with a primary key and a single element.
    assert_raise(Errno::ENOENT){bs.create :nofile}
  end

  ##################################################################
  ## USING THE SIMPLETEST FILE, THIS SHOULD CHECK INTEGRITY.

  def simpletest_tests(bs)
    #check to see if our internal description is correct.
    assert_equal(bs.tables.keys, [:simpletest])
    assert_equal(bs.tables[:simpletest].columns.keys, [:id, :test])
    #check to see if our database description is correct
    bs.connect do |db|
      assert_equal(db.tables, [:simpletest])
      assert_equal(db[:simpletest].columns, [:id, :test])
      #take down the table
      db.drop_table(:simpletest)
      assert_equal(db.tables, [])
    end
  end

  def test_create_table_using_symbol
    bs = Basie.new :name => "testdb"
    bs.create :simpletest
    simpletest_tests(bs)
  end

  def test_create_table_alt_directory
    bs = Basie.new :name => "testdb", :tabledir => "tables_alt"
    bs.create :simpletest
    simpletest_tests(bs)
  end

  def test_create_table_passing_path
    bs = Basie.new :name => "testdb"
    bs.create :simpletest, :path => File.join(Dir.pwd, "tables/simpletest.basie")
    simpletest_tests(bs)
  end

  def test_create_table_passing_file
    bs = Basie.new :name => "testdb"
    bs.create :simpletest, :file => File.new(File.join(Dir.pwd, "tables/simpletest.basie"))
    simpletest_tests(bs)
  end

  def test_create_table_passing_string
    bs = Basie.new :name => "testdb"
    bs.create :simpletest, :definition => File.new(File.join(Dir.pwd, "tables/simpletest.basie")).read
    simpletest_tests(bs)
  end

end