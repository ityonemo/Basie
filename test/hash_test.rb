#html_test.rb
#unit testing for hash-based basie files
require "sinatra"
require "test/unit"
require "rack/test"
require "json"

require_relative '../lib/basie'
require_relative 'test_databases'

class HashTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
  	Sinatra::Application
  end

  def setup
    $BS = Basie.new :name => "testdb"
    Basie.activate [:JSON, :HTML, :CSV]
    create [:hashtest, :simpletest]
  end

  def teardown
    $BS.cleanup
    Basie.purge_interfaces
  end

  #########################################################################
  ## TESTING TABLE ACCESSORS

  def test_access_data_by_hash
    assert_equal({:hash=>"G-qeUNuU2Ow8",:content=>"test 1"}, $BS.tables[:hashtest].data_by_id('G-qeUNuU2Ow8'))
  end

  def test_insert_data_with_hash
    $BS.tables[:hashtest].insert_data({:content => "test 4"})

    assert_equal [{:hash=>"G-qeUNuU2Ow8", :content=>"test 1"},
                  {:hash=>"bL_u2i6J__oH", :content=>"test 2"},
                  {:hash=>"skIgcPU7DmIR", :content=>"test 3"},
                  {:hash=>"0nMgA4Q61XNv", :content=>"test 4"}], $BS.tables[:hashtest].entire_table
  end

  def test_update_data_with_hash
    $BS.tables[:hashtest].update_data("G-qeUNuU2Ow8", {:content => "substituted"})

    assert_equal [{:hash=>"G-qeUNuU2Ow8", :content=>"substituted"},
                  {:hash=>"bL_u2i6J__oH", :content=>"test 2"},
                  {:hash=>"skIgcPU7DmIR", :content=>"test 3"}], $BS.tables[:hashtest].entire_table
  end

  ###########################################################################
  ## TESTING AGAINST ADVERSARIAL CONDITIONS

  def test_bad_hash_inputs
    #test malformed input for hash data access
    assert_raise (Basie::HashError){$BS.tables[:hashtest].data_by_id('not_a_real_hash')}
    #test well-formed but nonexistent input for hash data access
    assert_raise (Basie::NoHashError){$BS.tables[:hashtest].data_by_id('HashNotThere')}

    #test malformed input for hash data update
    assert_raise (Basie::HashError){$BS.tables[:hashtest].update_data('not_a_real_hash', {:content => "not to be changed"})}
    #and make sure we haven't altered the table.
    assert_equal [{:hash=>"G-qeUNuU2Ow8", :content=>"test 1"},
                  {:hash=>"bL_u2i6J__oH", :content=>"test 2"},
                  {:hash=>"skIgcPU7DmIR", :content=>"test 3"}], $BS.tables[:hashtest].entire_table

    #test well-formed but nonexistent input for hash data update.
    assert_raise (Basie::NoHashError){$BS.tables[:hashtest].update_data('HashNotThere', {:content => "not to be changed"})}
    #and make sure we haven't altered the table.
    assert_equal [{:hash=>"G-qeUNuU2Ow8", :content=>"test 1"},
                  {:hash=>"bL_u2i6J__oH", :content=>"test 2"},
                  {:hash=>"skIgcPU7DmIR", :content=>"test 3"}], $BS.tables[:hashtest].entire_table
  end

  #########################################################################
  ## TESTING REQUESTS

  def test_json_hashtable
  	get('/json/hashtest')

  	assert last_response.ok?
  	assert_equal File.new("./results/hashtest.json").read, last_response.body

    get ('/json/hashtest/G-qeUNuU2Ow8')
    assert last_response.ok?
    assert_equal File.new("./results/hashtest-part.json").read, last_response.body
  end

  def test_html_hashtable
    get ('/html/hashtest')

  	assert last_response.ok?
  	assert_equal File.new("./results/hashtest.ml").read, last_response.body

    get ('/html/hashtest/G-qeUNuU2Ow8')
    assert last_response.ok?
    assert_equal File.new("./results/hashtest-part.ml").read, last_response.body
  end

  def test_csv_hashtable
  	get('/csv/hashtest')

  	assert last_response.ok?
  	assert_equal File.new("./results/hashtest.csv").read, last_response.body

    get ('/json/hashtest/G-qeUNuU2Ow8')
    assert last_response.ok?
    assert_equal File.new("./results/hashtest-part.json").read, last_response.body
  end

  ###########################################################################
  ## TESTING DATA CREATION WITH HASHES

  

  ###########################################################################
  ## TESTING AGAINST ADVERSARIAL CONDITIONS

  def test_bad_hash_requests_json
  end
end