#user_test.rb
#unit testing for the user interface
require "sinatra"
require "test/unit"
require "rack/test"
require "json"

require_relative '../lib/basie'
require_relative 'test_databases'

class UserTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
  	Sinatra::Application
  end

  def setup
    $BS = Basie.new :name => "testdb"
    Basie.activate [:JSON, :User]
  end

  def teardown
    $BS.cleanup
    Basie.purge_interfaces
  end

  def test_user_basic
    create :usertest
  	#check to make sure that it starts with a clean slate.
  	get "/login"
  	assert last_response.ok?
  	assert_equal "", last_response.body

  	#attempt to log in.
  	post "/login", params = {:login => "user 1", :password => "user 1 pass"}
  	assert last_response.ok?

  	#check to see if our login has worked.
  	get "/login"
  	assert last_response.ok?
  	assert_equal "user 1", last_response.body

  	#check to see if we can log out
  	get "/logout"
  	assert last_response.ok?

  	#check to see if we have logged out.
  	get "/login"
  	assert last_response.ok?
  	assert_equal "", last_response.body
  end

  def test_user_badlogin
    create :usertest
  	#check to make sure that it starts with a clean slate.
  	get "/login"
  	assert last_response.ok?
  	assert_equal "", last_response.body

  	#attempt to log in.
  	post "/login", params = {:login => "user 1", :password => "user 1 past"}
  	#check we should have had a 403 error.
  	assert_equal 403, last_response.status

  	#check to see if we are not logged in
  	get "/login"
  	assert last_response.ok?
  	assert_equal "", last_response.body
  end
end