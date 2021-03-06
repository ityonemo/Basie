#suppress_test.rb
#unit testing for column 'suppress' directive
require "sinatra"
require "test/unit"
require "rack/test"
require "json"

require_relative '../lib/basie'
require_relative 'test_databases'

class SuppressTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
  	Sinatra::Application
  end

  def setup
    $BS = Basie.new :name => "testdb"
    Basie.activate [:JSON, :HTML, :CSV]
    $BS.enable_full_access

    create [:suppresstest]
  end

  def teardown
    $BS.cleanup
    Basie.purge_interfaces
    app.reset!
  end

  #########################################################################
  ## TESTING STATUS DETECTION
  def test_suppress_detection
    assert $BS.tables[:suppresstest].suppresslist == [:test2, :test3, :test4, :id]
  end

  def test_suppression_entire_table
    assert_equal [{:hash=>"zszwf8tWQsN3", :test=>"test 1"}], $BS.tables[:suppresstest].entire_table(:override_security => true)
  end

  def test_suppress_entire_table_restore_id
    assert_equal [{:id => 1, :hash=>"zszwf8tWQsN3", :test=>"test 1"}], $BS.tables[:suppresstest].entire_table(:restore => :id, :override_security => true)
  end

  def test_suppress_entire_table_restore_tests
    assert_equal [{:hash => "zszwf8tWQsN3",
                   :test => "test 1",
                   :test2 => "test 2",
                   :test3 => "test 3",
                   :test4 => "test 4"}], $BS.tables[:suppresstest].entire_table(:restore => [:test2, :test3, :test4], :override_security => true)
  end

  def test_suppress_entire_table_restore_all
    assert_equal [{:id => 1,
                   :hash =>"zszwf8tWQsN3",
                   :test =>"test 1",
                   :test2 => "test 2",
                   :test3 => "test 3",
                   :test4 => "test 4"}], $BS.tables[:suppresstest].entire_table(:restore => :all, :override_security => true)
  end

  def test_suppress_single_data
    assert_equal ({:hash=>"zszwf8tWQsN3", :test=>"test 1"}), $BS.tables[:suppresstest].data_by_id('zszwf8tWQsN3', :override_security => true)
  end

  def test_suppress_single_data_restore_id
    assert_equal ({:id => 1, :hash=>"zszwf8tWQsN3", :test=>"test 1"}), $BS.tables[:suppresstest].data_by_id('zszwf8tWQsN3', :restore => :id, :override_security => true)
  end

  def test_suppress_single_data_restore_tests
    assert_equal ({:hash=>"zszwf8tWQsN3",
                   :test=>"test 1",
                   :test2 => "test 2",
                   :test3 => "test 3",
                   :test4 => "test 4"}), $BS.tables[:suppresstest].data_by_id('zszwf8tWQsN3', :restore => [:test2, :test3, :test4], :override_security => true)
  end

  def test_suppress_single_data_restore_all
    assert_equal ({:id => 1,
                   :hash =>"zszwf8tWQsN3",
                   :test =>"test 1",
                   :test2 => "test 2",
                   :test3 => "test 3",
                   :test4 => "test 4"}), $BS.tables[:suppresstest].data_by_id('zszwf8tWQsN3', :restore => :all, :override_security => true)
  end

  def test_suppress_query
    assert_equal ({:hash=>"zszwf8tWQsN3", :test=>"test 1"}), $BS.tables[:suppresstest].data_by_query(:test, "test 1", :override_security => true)
  end

  def test_suppress_query_restore_id
    assert_equal ({:id => 1, :hash=>"zszwf8tWQsN3", :test=>"test 1"}), $BS.tables[:suppresstest].data_by_query(:test, "test 1", :restore => :id, :override_security => true)
  end

  def test_suppress_query_restore_tests
    assert_equal ({:hash=>"zszwf8tWQsN3",
                   :test=>"test 1",
                   :test2 => "test 2",
                   :test3 => "test 3",
                   :test4 => "test 4"}), $BS.tables[:suppresstest].data_by_query(:test, "test 1", :restore => [:test2, :test3, :test4], :override_security => true)
  end

  def test_suppress_query_restore_all
    assert_equal ({:id => 1,
                   :hash =>"zszwf8tWQsN3",
                   :test =>"test 1",
                   :test2 => "test 2",
                   :test3 => "test 3",
                   :test4 => "test 4"}), $BS.tables[:suppresstest].data_by_query(:test, "test 1", :restore => :all, :override_security => true)
  end

  def test_suppress_label
    assert_equal ({:hash=>"zszwf8tWQsN3", :test=>"test 1"}), $BS.tables[:suppresstest].data_by_label("test 1", :override_security => true)
  end

  def test_suppress_label_restore_id
    assert_equal ({:id => 1, :hash=>"zszwf8tWQsN3", :test=>"test 1"}), $BS.tables[:suppresstest].data_by_label("test 1", :restore => :id, :override_security => true)
  end

  def test_suppress_label_restore_tests
    assert_equal ({:hash=>"zszwf8tWQsN3",
                   :test=>"test 1",
                   :test2 => "test 2",
                   :test3 => "test 3",
                   :test4 => "test 4"}), $BS.tables[:suppresstest].data_by_label("test 1", :restore => [:test2, :test3, :test4], :override_security => true)
  end

  def test_suppress_label_restore_all
    assert_equal ({:id => 1,
                   :hash =>"zszwf8tWQsN3",
                   :test =>"test 1",
                   :test2 => "test 2",
                   :test3 => "test 3",
                   :test4 => "test 4"}), $BS.tables[:suppresstest].data_by_label("test 1", :restore => :all, :override_security => true)
  end
end
