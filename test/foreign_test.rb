#foreign_test.rb
#unit testing for basie foreign keys.
require "sinatra"
require "test/unit"
require "rack/test"

require_relative '../lib/basie'
require_relative 'test_databases'

class ForeignTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    $BS = Basie.new :name => "testdb"
    Basie.activate [:JSON, :HTML, :CSV]
    create [:righttest, :lefttest_nolink, :lefttest]
  end

  def teardown
    $BS.cleanup
    app.reset!
  end

  def test_foreign_bad
    #tests to make sure we can't make a foreign table that doesn't exist without raising an exception.
    assert_raise (Basie::NoTableError) {create :lefttest_bad}
  end

  def test_foreign_basic	
  	get('/json/lefttest')
  	assert last_response.ok?
  	assert_equal File.new("./results/foreigntest.json").read, last_response.body
  end

  def test_foreign_html
  	get ('/html/lefttest')
  	assert last_response.ok?
  	assert_equal File.new("./results/foreigntest.ml").read, last_response.body

    get ('/html/lefttest/1')
    assert last_response.ok?
    assert_equal File.new("./results/foreigntest-part.ml").read, last_response.body
  end

  def test_foreign_csv
  	get ('/csv/lefttest')
  	assert last_response.ok?
  	assert_equal File.new("./results/foreigntest.csv").read, last_response.body
  end

  def test_foreign_nolink
    get('/html/lefttest_nolink')
    assert last_response.ok?
    assert_equal File.new("./results/foreigntest-nolink.ml").read, last_response.body

    get ('/html/lefttest_nolink/1')
    assert last_response.ok?
    assert_equal File.new("./results/foreigntest-part-nolink.ml").read, last_response.body
  end
end