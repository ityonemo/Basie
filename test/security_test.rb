#security_test.rb
#unit testing for table security
require "sinatra"
require "test/unit"
require "rack/test"
require "json"

require_relative '../lib/basie'
require_relative 'test_databases'

class SecurityTest < Test::Unit::TestCase
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
    app.reset!
  end

  def test_security_data
    #allow full access.
    $BS.enable_full_access
    create [:usertest, :securitydata]

    #get the whole table
    get('/json/securitydata')
    #assertions about what the route we just triggered
    assert last_response.ok?

    assert_equal File.new("./results/securitydata.json").read, last_response.body
  end

  def test_public_restriction
    #write a security lambda that defines public to have no access
    #and logged in parties to have full access
    public_restrict = lambda do |x, t|
      if x == :public
        {:read => nil, :write => nil}
      else
        {:read => "", :write => "{|l| l}"}
      end
    end

    $BS.set_access_generator(public_restrict)

    create [:usertest, :securitydata]

    #get the whole table
    get('/json/securitydata')
    assert_equal 403, last_response.status

    #get just one index

    #attempt to write
    
  end

end
