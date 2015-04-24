#post_test.rb
#unit testing for the Basie::POSTInterpreter object
require "sinatra"
require "test/unit"
require "rack/test"

require_relative '../lib/basie'
require_relative 'test_databases'

class POSTTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    $BS = Basie.new :name => "testdb"
    Basie.activate :POST
    $BS.enable_full_access

    create [:simpletest, :hashtest]
  end

  def teardown
    $BS.cleanup
    Basie.purge_interfaces
    app.reset!
  end

  #test the basic route
  def test_post_insert_data

    post "/db/simpletest", params = {:test => "four"}

    #make sure this responded ok
    assert last_response.success?

    #make sure that the table looks as it should.
    assert_equal [{:id=>1, :test=>"one"},{:id=>2, :test=>"two"},{:id=>3, :test=>"two"},{:id=>4, :test=>"four"}], $BS.tables[:simpletest].entire_table(:session => {})
  end

  def test_post_update_data
    post "/db/simpletest/1", params = {:test => "substituted"}
    #make sure this responded ok
    assert last_response.success?
    #make sure note that the result is that the first id item has been changed.
    assert_equal [{:id=>1, :test=>"substituted"},{:id=>2, :test=>"two"},{:id=>3, :test=>"two"}], $BS.tables[:simpletest].entire_table(:session => {})
  end

  def test_post_update_data_with_hash
    post "/db/hashtest/G-qeUNuU2Ow8", params = {:content => "substituted"}
    #make sure this responded ok

    assert last_response.success?
    #make sure note that the result is that the first id item has been changed.
    assert_equal [{:hash=>"G-qeUNuU2Ow8",:content=>"substituted"},
                  {:hash=>"bL_u2i6J__oH",:content=>"test 2"},
                  {:hash=>"skIgcPU7DmIR",:content=>"test 3"}], $BS.tables[:hashtest].entire_table(:session => {})
  end

  #####################################################################################333
  ## SOME ADVERSARIAL TESTS

  def test_attempt_to_write_nonexistent_id
    post "/db/simpletest/4", params = {:test => "nonexistent"}

    assert_equal 404, last_response.status
  end

  def test_attempt_to_write_nonexistent_hash
    post "/db/hashtest/NotAHashFool", params = {:content => "nonexistent"}

    assert_equal 404, last_response.status
  end

  def test_attempt_to_overwrite_id
    #this directive contains a sneaky attempt to write in an id.
    post "/db/simpletest/1", params = {:id=>4, :test => "substituted"}
    #make sure this responded ok
    assert last_response.success?
    #make sure note that the result is that the first id item has been changed.
    assert_equal [{:id=>1, :test=>"substituted"},{:id=>2, :test=>"two"},{:id=>3, :test=>"two"}], $BS.tables[:simpletest].entire_table(:session => {})
  end

  def test_attempt_to_overwrite_hash
    post "/db/hashtest/G-qeUNuU2Ow8", params = {:content => "substituted", :hash => "overwriteme"}
    #make sure this responded ok
    assert last_response.success?
    #make sure note that the result is that the first id item has been changed.
    assert_equal [{:hash=>"G-qeUNuU2Ow8",:content=>"substituted"},
                  {:hash=>"bL_u2i6J__oH",:content=>"test 2"},
                  {:hash=>"skIgcPU7DmIR",:content=>"test 3"}], $BS.tables[:hashtest].entire_table(:session => {})
  end

end
