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
    Basie.activate [:JSON, :HTML, :CSV]
    create :hashtest
  end

  def teardown
    destroy :hashtest
    Basie.purge_interfaces
  end


  def test_json_hashtable
  	get('/json/hashtest')

  	assert last_response.ok?
  	assert_equal File.new("./results/hashtest.json").read, last_response.body
  end

  def test_html_hashtable
    get ('html/hashtest')

  	assert last_response.ok?
  	assert_equal File.new("./results/hashtest.ml").read, last_response.body
  end

  def test_csv_hashtable
  	get('/csv/hashtest')

  	assert last_response.ok?
  	assert_equal File.new("./results/hashtest.csv").read, last_response.body
  end
end