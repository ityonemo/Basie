#table_test.rb
#unit testing for the Basie::JSONInterpreter object
require "sinatra"
require "test/unit"
require "rack/test"
require "json"
require_relative '../lib/basie'

class TableTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  #test the basic route
  def test_fulltable_route
  	bs = Basie.new :name => "testdb"

  	bs.connect do |db|
  		db.drop_table?(:simpletest)
  	end

    bs.create :simpletest

    #pre-prepping
    bs.connect do |db|
    	#insert some sample data here.
    	db[:simpletest].insert(:test => "one")
    	db[:simpletest].insert(:test => "two")
    end

    #run the damn thing
    get('/json/simpletest')

    #assertions about what the route we just triggered
    assert last_response.ok?
    #check the resulting data after a JSON parse.
    #remember, JSON.parse does NOT assign keys of Javascript hashes to symbols
    #associative arrays are, instead, assigned to strings.
    assert_equal [{"id" => 1, "test" => "one"}, {"id" => 2, "test" => "two"}], JSON.parse(last_response.body)
  end
end