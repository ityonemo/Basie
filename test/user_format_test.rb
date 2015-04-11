#user_format_test.rb
#unit testing formatting for the Basie::UserInterpreter object's LoginForm directive.
require "sinatra"
require "test/unit"
require "rack/test"
require "json"

require_relative '../lib/basie'
require_relative 'test_databases'

class UserFormatTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  #####################################################################################
  ##### PLAYING WITH CSS

  def set_up(params = {})
  	#because we must pass parameters for setting up with different conditions, we can't use the default "setup" method
    $BS = Basie.new :name => "testdb"
    Basie.purge_interfaces #just in case it hasn't been done and there's carryover from a previous basie run.
    Basie.activate :User, params

    create params[:table]
  end

  def teardown
    $BS.cleanup
  	Basie.purge_interfaces
  end

  def test_default_login
  	set_up :table => :usertest

  	get ('/loginform')

  	assert last_response.ok?
  	assert_equal File.new("./results/simpleuser-form.ml").read, last_response.body
  end

  def test_default_nojs_login
  	set_up :table => :usertest

  	get ('/loginform?redirect=false')

  	assert last_response.ok?
  	assert_equal File.new("./results/simpleuser-form-nojs.ml").read, last_response.body
  end
end