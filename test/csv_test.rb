#html_test.rb
#unit testing for the Basie::HTMLInterpreter object
require "sinatra"
require "test/unit"
require "rack/test"
require "json"

require_relative '../lib/basie'
require_relative 'test_databases'

class CSVTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    Basie.activate :CSV

    create :simpletest
  end

  def teardown
    destroy :simpletest

    Basie.purge_interfaces
  end

  #test the basic route
  def test_fulltable_route
    #run the damn thing
    get('/csv/simpletest')

    #assertions about what the route we just triggered
    assert last_response.ok?
    assert_equal File.new("./results/simpletest.csv").read, last_response.body
  end

  def test_id_query_route
    #get just one line
    get ('/csv/simpletest/1')

    #assertions about what the route we just triggered
    assert last_response.ok?
    assert_equal "\"id\",\"test\"\n\"1\",\"one\"\n", last_response.body
  end

  def test_specific_query_route
    #get one line where we've preselected the data
    #get just one line
    get('/csv/simpletest/test/one')

    #assertions about what the route we just triggered
    assert last_response.ok?
    assert_equal "\"id\",\"test\"\n\"1\",\"one\"\n", last_response.body
  end
end