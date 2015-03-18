#table_test.rb
#unit testing for the Basie::JSONInterpreter object
require "sinatra"
require "test/unit"
require "rack/test"
require "json"
require_relative '../lib/basie'
require_relative 'test_databases'

class JSONTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    $BS = Basie.new :name => "testdb"
    Basie.activate :JSON
    create :simpletest
  end

  def teardown
    destroy :simpletest
    Basie.purge_interfaces
  end

  #test the basic route
  def test_fulltable_route
    #get the whole table
    get('/json/simpletest')

    #assertions about what the route we just triggered
    assert last_response.ok?
    assert_equal File.new("./results/simpletest.json").read, last_response.body
  end

  def test_id_query_route
    #get just one line
    get('/json/simpletest/1')

    #assertions about what the route we just triggered
    assert last_response.ok?
    #check the resulting data after a JSON parse.
    #remember, JSON.parse does NOT assign keys of Javascript hashes to symbols
    #associative arrays are, instead, assigned to strings.
    assert_equal '{"id":1,"test":"one"}', last_response.body
  end

  def test_specific_query_route
    #get one line where we've preselected the data

    #get just one line
    get('/json/simpletest/test/one')

    #assertions about what the route we just triggered
    assert last_response.ok?
    #check the resulting data after a JSON parse.
    #remember, JSON.parse does NOT assign keys of Javascript hashes to symbols
    #associative arrays are, instead, assigned to strings.
    assert_equal '{"id":1,"test":"one"}', last_response.body
  end
end