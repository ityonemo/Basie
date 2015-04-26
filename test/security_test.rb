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
    Basie.activate [:JSON, :HTML, :CSV, :POST, :User]
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

  def test403s(prefix)
    #get the entire table
    get(prefix + "/securitydata")
    assert_equal 403, last_response.status

    #get by hash
    get(prefix + "/securitydata/gHroYdCkdch8")
    assert_equal 403, last_response.status

    #get by query
    get(prefix + "/securitydata/owner/1")
    assert_equal 403, last_response.status
  end

  def test_public_restriction
    #write a security lambda that defines public to have no access
    #and logged in parties to have full access
    public_restrict = lambda do |x, t|
      if x == :public
        {:read => nil, :write => "nil"}
      else
        {:read => "", :write => "{|l| l}"}
      end
    end

    $BS.set_access_generator(public_restrict)

    create [:usertest, :securitydata]

    #test json
    test403s("/json")
    #test csv
    test403s("/csv")
    #test html
    test403s("/html")

    original_data = $BS.tables[:securitydata].entire_table(:override_security => true)
    #test writing a data entry
    post "/db/securitydata", :params => {"data":4,"owner":1}
    assert_equal 403, last_response.status
    #double check the integrity of the table.
    assert_equal original_data, $BS.tables[:securitydata].entire_table(:override_security => true)

    #test replacing a data entry
    post "/db/securitydata/gHroYdCkdch8", :params => {"data":4,"owner":1}
    assert_equal 403, last_response.status
    #double check the integrity of the table.
    assert_equal original_data, $BS.tables[:securitydata].entire_table(:override_security => true)

    #test using CSV
  end

end
