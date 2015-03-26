#html_test.rb
#unit testing for the Basie::HTMLInterpreter object
require "sinatra"
require "test/unit"
require "rack/test"
require "json"

require_relative '../lib/basie'
require_relative 'test_databases'

class HTMLTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    $BS = Basie.new :name => "testdb"
    Basie.activate :HTML
    create [:simpletest, :complextest, :urltest, :emailtest, :teltest]
  end

  def teardown
    $BS.cleanup
    Basie.purge_interfaces
  end

  def test_column_integer_default_hash
    cl = Basie::Column.new("Integer :test")
    assert_equal :test,     cl.name
    assert_equal :integer,  cl.type
    assert_equal :number,   cl.params[:htag]
  end

  def test_column_boolean_default_hash
    cl = Basie::Column.new("boolean :test")
    assert_equal :test,     cl.name
    assert_equal :boolean,  cl.type
    assert_equal :checkbox, cl.params[:htag]
  end

  #test to see if the plugin will correctly parse column settings
  def test_column_integer_suppression
    cl = Basie::Column.new("Integer :test     #suppress")
    assert_equal :test,     cl.name
    assert_equal :integer,  cl.type
    assert_equal :suppress, cl.params[:htag]
  end

  def test_column_url_htag
    cl = Basie::Column.new("String :test    #url")
    assert_equal :test,     cl.name
    assert_equal :varchar,  cl.type
    assert_equal :url,      cl.params[:htag]
  end

  #test the basic route
  def test_fulltable_route
    get('/html/simpletest')

    #assertions about what the route we just triggered
    assert last_response.ok?
    assert_equal File.new("./results/simpletest.ml").read, last_response.body
  end

  def test_id_query_route
    get ('/html/simpletest/1')

    #assertions about what the route we just triggered
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part.ml").read, last_response.body
  end

  def test_specific_query_route

    #get just one line
    get('/html/simpletest/test/one')

    #assertions about what the route we just triggered
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part.ml").read, last_response.body
  end

  def test_multiple_query_route
    #should retrieve more than one line.
    get('/html/simpletest/test/two')

    #assertions about what the route we just triggered
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-multiple-part.ml").read, last_response.body
  end

  def test_input_form
    get('/htmlform/simpletest')

    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form.ml").read, last_response.body
  end

  def test_input_form_with_data
    get('/htmlform/simpletest/1')

    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-with-data.ml").read, last_response.body
  end

  def test_input_form_complex
    get('htmlform/complextest')

    assert last_response.ok?
    assert_equal File.new("./results/complextest-form.ml").read, last_response.body
  end

  ##############################################################################3
  ### ADDING HTML TAGS FOR SPECIALIZED DATA

  def test_url
    get('/html/urltest')
    assert last_response.ok?
    assert_equal File.new("./results/urltest.ml").read, last_response.body

    get('/html/urltest/1')
    assert last_response.ok?
    assert_equal File.new("./results/urltest-part.ml").read, last_response.body
  end

  def test_email
    get('/html/emailtest')
    assert last_response.ok?
    assert_equal File.new("./results/emailtest.ml").read, last_response.body

    get('/html/emailtest/1')
    assert last_response.ok?
    assert_equal File.new("./results/emailtest-part.ml").read, last_response.body
  end

  def test_tel
    get('/html/teltest')
    assert last_response.ok?
    assert_equal File.new("./results/teltest.ml").read, last_response.body

    get('/html/teltest/1')
    assert last_response.ok?
    assert_equal File.new("./results/teltest-part.ml").read, last_response.body
  end
end