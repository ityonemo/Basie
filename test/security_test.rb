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
        {:read => nil, :write => "{|l| nil}"}
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
    post "/db/securitydata", params = {"data" => 4,"owner" => 1}
    assert_equal 403, last_response.status
    #double check the integrity of the table.
    assert_equal original_data, $BS.tables[:securitydata].entire_table(:override_security => true)

    #test replacing a data entry
    post "/db/securitydata/gHroYdCkdch8", params = {"data" => 4,"owner" => 1}
    assert_equal 403, last_response.status
    #double check the integrity of the table.
    assert_equal original_data, $BS.tables[:securitydata].entire_table(:override_security => true)

    #test using CSV
    post '/csv/securitydata', 'securitydata' => Rack::Test::UploadedFile.new('results/securityappend.csv', 'text/csv')
    assert_equal 403, last_response.status
    #double check the integrity of the table.
    assert_equal original_data, $BS.tables[:securitydata].entire_table(:override_security => true)
  end

  def test_restricting_read_based_on_user_id
    user_restrict = lambda do |x, t|
      if x == :public
        {:read => nil, :write => "{|l| nil}"}
      else
        {:read => "securitydata.owner = '#{x[:id]}'", :write => "{|l| l}"}
      end
    end

    $BS.set_access_generator(user_restrict)

    create [:usertest, :securitydata]

    #make sure that with the new protocol we still get 403s without login
    test403s("/json")

    #now, login.
  	post '/login', params = {:login => "user 1", :password => "user 1 pass"}
  	assert last_response.ok?

    #now, get the list
    get '/json/securitydata'
    assert last_response.ok?
    assert_equal File.new("./results/securitydata-user1.json").read, last_response.body

    #logout
    get '/logout'
    assert last_response.ok?

    #login, as user 2
    post "/login", params = {:login => "user 2", :password => "user 2 pass"}
    assert last_response.ok?

    #now, get the list

    get '/json/securitydata'
    assert last_response.ok?
    assert_equal File.new("./results/securitydata-user2.json").read, last_response.body

    get '/json/securitydata'
    old_response = last_response.body

    #an adversarial test showing that this security scheme can have a problem.
    post "/db/securitydata", params = {"data" => 4,"owner" => 1}
    assert last_response.success?

    get '/json/securitydata'
    assert last_response.ok?
    assert_equal old_response, last_response.body
    #note that this is correct (as defined) but generally a poor choice
    #becaues you don't want owner 2 to be able to write an item with owner 1
  end

  def test_restricting_write_based_on_user_id
    user_restrict = lambda do |x, t|
      if x == :public
        {:read => nil, :write => "{|l| nil}"}
      else
        {:read => "owner = #{x[:id]}", :write => "{|l| l['owner'] = #{x[:id]}; l}"}
      end
    end

    $BS.set_access_generator(user_restrict)

    create [:usertest, :securitydata]

    #make sure that with the new protocol we still get 403s without login
    test403s("/json")

    #now, login.
    post '/login', params = {:login => "user 1", :password => "user 1 pass"}
    assert last_response.ok?

    #attempt to post data with adversarial owner data that will be rebranded.
    post '/db/securitydata', params = {"data" => 4,"owner" => 1}
    assert last_response.success?

    #now, get the full data
    get '/json/securitydata'
    assert last_response.ok?
    assert_equal File.new("./results/securitydata-appendone.json").read,
      last_response.body

    #logout
    get '/logout'
    assert last_response.ok?

    #login, as user 2
    post "/login", params = {:login => "user 2", :password => "user 2 pass"}
    assert last_response.ok?

    #check to make sure matching params to the user works.
    post '/db/securitydata', params = {"data" => 5,"owner" => 1}
    assert last_response.success?

    #now, get the list
    get '/json/securitydata'
    assert last_response.ok?
    assert_equal File.new("./results/securitydata-appendtwo.json").read,
      last_response.body
  end

end
