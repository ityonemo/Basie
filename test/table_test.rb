#table_test.rb
#unit testing for the Basie::Table object

require "test/unit"
require "rack/test"
require_relative '../lib/basie'

require_relative './test_databases'

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
    assert_equal      [:simpletest],          bs.tables.keys
    assert_equal      [:id, :test],           bs.tables[:simpletest].columns.keys
    #check to see if our database description is correct
    bs.connect do |db|
      assert_equal    [:simpletest],          db.tables
      assert_equal    [:id, :test],           db[:simpletest].columns
      #take down the table
      db.drop_table(:simpletest)
      assert_equal    [],                     db.tables
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

  #########################################################################################33
  ## TESTING ACCESSORS

  def test_entire_table
    create :simpletest
    assert_equal [{:id=>1, :test=>"one"},{:id=>2, :test=>"two"}], $BS.tables[:simpletest].entire_table
    destroy :simpletest
  end

  def test_data_by_id
    create :simpletest
    assert_equal(({:id=>1, :test=>"one"}), $BS.tables[:simpletest].data_by_id(1))
    destroy :simpletest
  end

  def test_data_by_hash
    create :hashtest
    assert_equal(({:hash=>"G-qeUNuU2Ow8", :content=>"test 1"}), $BS.tables[:hashtest].data_by_id(1))
    assert_equal(({:hash=>"G-qeUNuU2Ow8", :content=>"test 1"}), $BS.tables[:hashtest].data_by_id("G-qeUNuU2Ow8"))
    destroy :hashtest
  end

  def test_data_by_search
#    create :simpletest
#    assert_equal(({:id=>1, :test=>"one"}), $BS.tables[:simpletest].data_by_id(1))
#   destroy :simpletest
  end

  def test_data_by_query
    create :simpletest
    assert_equal(({:id=>1, :test=>"one"}), $BS.tables[:simpletest].data_by_query(:test, "one"))
    destroy :simpletest
  end

  def test_insert_data_hash
    bs = Basie.new :name => "testdb"
    bs.connect{|db| db.drop_table? :simpletest}
    bs.create :simpletest
    bs.tables[:simpletest].insert_data(:test => "one")
    assert_equal [{:id=>1, :test=>"one"}], bs.tables[:simpletest].entire_table
    bs.connect {|db| db.drop_table(:simpletest)}
  end

  def test_insert_data_array
    bs = Basie.new :name => "testdb"
    bs.connect{|db| db.drop_table? :simpletest}
    bs.create :simpletest
    bs.tables[:simpletest].insert_data([{:test => "one"},{:test => "two"}])
    assert_equal [{:id=>1, :test=>"one"}, {:id=>2, :test=>"two"}], bs.tables[:simpletest].entire_table
    bs.connect {|db| db.drop_table(:simpletest)}
  end

  def test_update_data_by_id
    bs = Basie.new :name => "testdb"
    bs.connect{|db| db.drop_table? :simpletest}
    bs.create :simpletest
    bs.tables[:simpletest].insert_data(:test => "one")
    assert_equal [{:id=>1, :test=>"one"}], bs.tables[:simpletest].entire_table
    bs.tables[:simpletest].update_data(1, {:test => "two"})
    assert_equal [{:id=>1, :test=>"two"}], bs.tables[:simpletest].entire_table
    bs.connect {|db| db.drop_table(:simpletest)}
  end

  def test_update_data_by_hash
    bs = Basie.new :name => "testdb"
    bs.connect{|db| db.drop_table? :hashtest}
    bs.create :hashtest
    bs.tables[:hashtest].insert_data(:content => "test 1")
    assert_equal [{:hash=>"G-qeUNuU2Ow8", :content=>"test 1"}], bs.tables[:hashtest].entire_table
    bs.tables[:hashtest].update_data(1, {:content => "test 2"})
    assert_equal [{:hash=>"G-qeUNuU2Ow8", :content=>"test 2"}], bs.tables[:hashtest].entire_table
    bs.tables[:hashtest].update_data("G-qeUNuU2Ow8", {:content => "test 3"})
    assert_equal [{:hash=>"G-qeUNuU2Ow8", :content=>"test 3"}], bs.tables[:hashtest].entire_table
    bs.connect {|db| db.drop_table(:hashtest)}
  end
end