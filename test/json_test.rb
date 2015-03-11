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

  #test the basic route
  def test_fulltable_route

    create_simpletest

    #run the damn thing
    get('/json/simpletest')

    #assertions about what the route we just triggered
    assert last_response.ok?
    #check the resulting data after a JSON parse.
    #remember, JSON.parse does NOT assign keys of Javascript hashes to symbols
    #associative arrays are, instead, assigned to strings.
    assert_equal last_response.body, File.new("./results/simpletest.json").read
  end
end