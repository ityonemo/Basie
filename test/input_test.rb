#input_test.rb
#unit testing for basic database entry
require "sinatra"
require "test/unit"
require "rack/test"

require_relative '../lib/basie'
require_relative 'test_databases'

class INPUTTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
  	Sinatra::Application
  end

  def setup
    Basie.activate :HTML
  end

  def test_basic_input
  	#create :inputtest

  	#get("/htmlform/inputtest")

  	#assert request_ok?

  	#puts request.body
  	#assert_equal 

    #destroy :inputtest
  end

end