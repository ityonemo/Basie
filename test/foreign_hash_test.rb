#foreign_test.rb
#unit testing for basie foreign keys.
require "sinatra"
require "test/unit"
require "rack/test"

require_relative '../lib/basie'
require_relative 'test_databases'

class ForeignHashTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
  	$BS = Basie.new :name => "testdb"
    Basie.activate :HTML
    create [:righttest_hash, :lefttest_hash]
  end

  def teardown
    $BS.cleanup
  end

  def test_foreign_hash_html
  	get ('/html/lefttest_hash')
  	assert last_response.ok?
  	assert_equal File.new("./results/foreigntest-hash.ml").read, last_response.body

    #get ('/html/lefttest_hash/1')
    #assert last_response.ok?
    #puts last_response.body
    #assert_equal File.new("./results/foreigntest-part.ml").read, last_response.body
  end
end