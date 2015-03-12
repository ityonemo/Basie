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
    Basie.interpret :HTML
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

  	create_simpletest

    #run the damn thing
    get('/html/simpletest')

    #assertions about what the route we just triggered
    assert last_response.ok?
    #check the resulting data after a JSON parse.
    #remember, JSON.parse does NOT assign keys of Javascript hashes to symbols
    #associative arrays are, instead, assigned to strings.
    assert_equal File.new("./results/simpletest.ml").read, last_response.body
  end

  def test_id_query_route
    create_simpletest

    #get just one line
    get ('/html/simpletest/1')

    #assertions about what the route we just triggered
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part.ml").read, last_response.body
  end

  def test_specific_query_route
    create_simpletest

    #get one line where we've preselected the data

    #get just one line
    get('/html/simpletest/test/one')

    #assertions about what the route we just triggered
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part.ml").read, last_response.body
  end
end