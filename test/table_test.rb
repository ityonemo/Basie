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

  def setup
    @session = {:login => nil}
  end

  #TEST CREATING A TABLE.  These methods should emanate from the basie object.

  def teardown
    $BS.cleanup
  end

  def test_create_table_no_symbol_argument
    #should not create a blank table
    assert_raise(ArgumentError){$BS.create "wrong input"}
  end

  def test_create_table_no_definition_file
    #create a blank table, with a primary key and a single element.
    assert_raise(Errno::ENOENT){$BS.create :nofile}
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
    end
  end

  def test_create_table_using_symbol
    $BS = Basie.new :name => "testdb"
    $BS.enable_full_access

    $BS.create :simpletest
    simpletest_tests($BS)
  end

  def test_create_table_alt_directory
    $BS = Basie.new :name => "testdb", :tabledir => "tables_alt"
    $BS.enable_full_access

    $BS.create :simpletest
    simpletest_tests($BS)
  end

  def test_create_table_passing_path
    $BS = Basie.new :name => "testdb"
    $BS.enable_full_access

    $BS.create :simpletest, :path => File.join(Dir.pwd, "tables/simpletest.basie")
    simpletest_tests($BS)
  end

  def test_create_table_passing_file
    $BS = Basie.new :name => "testdb"
    $BS.enable_full_access

    $BS.create :simpletest, :file => File.new(File.join(Dir.pwd, "tables/simpletest.basie"))
    simpletest_tests($BS)
  end

  def test_create_table_passing_string
    $BS = Basie.new :name => "testdb"
    $BS.enable_full_access

    $BS.create :simpletest, :definition => File.new(File.join(Dir.pwd, "tables/simpletest.basie")).read
    simpletest_tests($BS)
  end

  #########################################################################################33
  ## DATA ACCESS (ACCESSORS)

  def test_entire_table
    $BS = Basie.new :name => "testdb"
    $BS.enable_full_access

    create :simpletest
    assert_equal [{:id=>1, :test=>"one"},{:id=>2, :test=>"two"},{:id=>3, :test=>"two"}],
      $BS.tables[:simpletest].entire_table(:session => @session)
  end

  def test_data_by_id
    $BS = Basie.new :name => "testdb"
    $BS.enable_full_access

    create :simpletest
    assert_equal(({:id=>1, :test=>"one"}),
      $BS.tables[:simpletest].data_by_id(1, :session => @session))
  end

  def test_data_by_query
    $BS = Basie.new :name => "testdb"
    $BS.enable_full_access

    create :simpletest
    assert_equal(({:id=>1, :test=>"one"}),
      $BS.tables[:simpletest].data_by_query(:test, "one", :session => @session))
  end

  def test_data_by_dual_query
    $BS = Basie.new :name => "testdb"
    $BS.enable_full_access

    create :simpletest
    assert_equal([{:id=>2, :test=>"two"}, {:id=>3, :test=>"two"}],
      $BS.tables[:simpletest].data_by_query(:test, "two", :session => @session))
  end

  ######################################################################################
  ## DATA INSERTION

  def test_insert_data_hash
    $BS = Basie.new :name => "testdb"
    $BS.enable_full_access

    $BS.connect{|db| db.drop_table? :simpletest}
    $BS.create :simpletest
    $BS.tables[:simpletest].insert_data({:test => "one"}, :session => @session)
    assert_equal [{:id=>1, :test=>"one"}], $BS.tables[:simpletest].entire_table(:session => @session)
  end

  def test_insert_data_array
    $BS = Basie.new :name => "testdb"
    $BS.enable_full_access

    $BS.connect{|db| db.drop_table? :simpletest}
    $BS.create :simpletest

    $BS.tables[:simpletest].insert_data([{:test => "one"},{:test => "two"}], :session => @session)
    assert_equal [{:id=>1, :test=>"one"}, {:id=>2, :test=>"two"}], $BS.tables[:simpletest].entire_table(:session => @session)
  end

  def test_update_data_by_id
    $BS = Basie.new :name => "testdb"
    $BS.enable_full_access

    create :simpletest
    $BS.tables[:simpletest].update_data(1, {:test => "substituted"}, :session => @session)
    assert_equal [{:id=>1, :test=>"substituted"},{:id=>2, :test=>"two"},{:id=>3, :test=>"two"}],
      $BS.tables[:simpletest].entire_table(:session => @session)
  end

  #############################################################################3
  ## ADVERSARIAL TESTING

  def test_retrieve_data_nonexistent_id
    $BS = Basie.new :name => "testdb"
    $BS.enable_full_access

    create :simpletest
    assert_raise (Basie::NoIdError){$BS.tables[:simpletest].data_by_id(4, :session => @session)}
  end

  def test_update_data_nonexistent_id
    $BS = Basie.new :name => "testdb"
    $BS.enable_full_access

    create :simpletest
    assert_raise (Basie::NoIdError){$BS.tables[:simpletest].update_data(4, {:test => "substituted"}, :session => @session)}
  end
end
