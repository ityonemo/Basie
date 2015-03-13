#html_test.rb
#unit testing for the Basie::HTMLInterpreter object
require "sinatra"
require "test/unit"
require "rack/test"
require "json"

require_relative '../lib/basie'
require_relative 'test_databases'

class HTMLTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    Basie.interpret :HTML
  end

  def test_column_integer_default_hash
    cl = Basie::Column.new("Integer :test")
    assert_equal :test,     cl.name
    assert_equal :integer,  cl.type
    assert_equal :number,   cl.params[:htag]
  end

  def test_column_boolean_default_hash
    cl = Basie::Column.new("boolean :test")
    assert_equal :test,     cl.name
    assert_equal :boolean,  cl.type
    assert_equal :checkbox, cl.params[:htag]
  end

  #test to see if the plugin will correctly parse column settings
  def test_column_integer_suppression
    cl = Basie::Column.new("Integer :test     #suppress")
    assert_equal :test,     cl.name
    assert_equal :integer,  cl.type
    assert_equal :suppress, cl.params[:htag]
  end

  def test_column_url_htag
    cl = Basie::Column.new("String :test    #url")
    assert_equal :test,     cl.name
    assert_equal :varchar,  cl.type
    assert_equal :url,      cl.params[:htag]
  end

  #test the basic route
  def test_fulltable_route
  	create :simpletest
    #run the damn thing
    get('/html/simpletest')

    #assertions about what the route we just triggered
    assert last_response.ok?
    #check the resulting data after a JSON parse.
    #remember, JSON.parse does NOT assign keys of Javascript hashes to symbols
    #associative arrays are, instead, assigned to strings.
    assert_equal File.new("./results/simpletest.ml").read, last_response.body

    destroy :simpletest
  end

  def test_id_query_route
    create :simpletest

    #get just one line
    get ('/html/simpletest/1')

    #assertions about what the route we just triggered
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part.ml").read, last_response.body

    destroy :simpletest
  end

  def test_specific_query_route
    create :simpletest

    #get one line where we've preselected the data

    #get just one line
    get('/html/simpletest/test/one')

    #assertions about what the route we just triggered
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part.ml").read, last_response.body

    destroy :simpletest
  end

  #####################################################################################333
  ##### PLAYING WITH CSS

  def test_table_id_suppression
    Basie.purge_interpreters
    Basie.interpret :HTML, :no_table_id => true

    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-no-table-id.ml").read, last_response.body

    destroy :simpletest

    Basie.purge_interpreters
    Basie.interpret :HTML
  end

  def test_table_id_substitution
    Basie.purge_interpreters
    Basie.interpret :HTML, :table_id => "substituted"

    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-sub-table-id.ml").read, last_response.body

    destroy :simpletest

    Basie.purge_interpreters
    Basie.interpret :HTML
  end

  def test_header_class_suppression
    Basie.purge_interpreters
    Basie.interpret :HTML, :no_header_class => true

    create :simpletest
    get('/html/simpletest')

    assert last_response.ok?
    assert_equal File.new("./results/simpletest-no-header-class.ml").read, last_response.body

    destroy :simpletest

    Basie.purge_interpreters
    Basie.interpret :HTML
  end

  def test_header_class_substitution
    Basie.purge_interpreters
    Basie.interpret :HTML, :header_class => "substituted"

    create :simpletest
    get('/html/simpletest')

    assert last_response.ok?
    assert_equal File.new("./results/simpletest-sub-header-class.ml").read, last_response.body

    destroy :simpletest

    Basie.purge_interpreters
    Basie.interpret :HTML
  end

  def test_column_class_removal
    Basie.purge_interpreters
    Basie.interpret :HTML, :column_class => false

    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-no-column-class.ml").read, last_response.body

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-no-column-class.ml").read, last_response.body

    destroy :simpletest

    Basie.purge_interpreters
    Basie.interpret :HTML
  end  

  def test_column_class_proc
    Basie.purge_interpreters
    Basie.interpret :HTML, :column_class => Proc.new{|col| col == :id ? "substituted" : false}

    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-sub-column-class.ml").read, last_response.body

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-sub-column-class.ml").read, last_response.body

    destroy :simpletest

    Basie.purge_interpreters
    Basie.interpret :HTML
  end

  def test_column_class_hash
    Basie.purge_interpreters
    Basie.interpret :HTML, :column_class => {:id => "substituted", :test => false}

    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-sub-column-class.ml").read, last_response.body


    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-sub-column-class.ml").read, last_response.body

    destroy :simpletest

    Basie.purge_interpreters
    Basie.interpret :HTML
  end

  def test_header_id_removal
    Basie.purge_interpreters
    Basie.interpret :HTML, :header_id => false

    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-no-header-id.ml").read, last_response.body

    destroy :simpletest

    Basie.purge_interpreters
    Basie.interpret :HTML
  end  

  def test_header_id_proc
    Basie.purge_interpreters
    Basie.interpret :HTML, :header_id => Proc.new{|col| col == :id ? "substituted" : false}

    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-sub-header-id.ml").read, last_response.body

    destroy :simpletest

    Basie.purge_interpreters
    Basie.interpret :HTML
  end

  def test_header_id_hash
    Basie.purge_interpreters
    Basie.interpret :HTML, :header_id => {:id => "substituted", :test => false}

    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-sub-header-id.ml").read, last_response.body

    destroy :simpletest

    Basie.purge_interpreters
    Basie.interpret :HTML
  end

  def test_entry_id_suppression
    Basie.purge_interpreters
    Basie.interpret :HTML, :no_entry_id => true

    create :simpletest

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-no-entry-id.ml").read, last_response.body

    destroy :simpletest

    Basie.purge_interpreters
    Basie.interpret :HTML
  end

  def test_entry_id_substitution
    Basie.purge_interpreters
    Basie.interpret :HTML, :entry_id => "substituted"

    create :simpletest

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-sub-entry-id.ml").read, last_response.body

    destroy :simpletest

    Basie.purge_interpreters
    Basie.interpret :HTML
  end

  ##############################################################################3
  ### ADDING HTML TAGS FOR SPECIALIZED DATA

  def test_url
    create :urltest

    get('/html/urltest')
    assert last_response.ok?
    assert_equal File.new("./results/urltest.ml").read, last_response.body

    get('/html/urltest/1')
    assert last_response.ok?
    assert_equal File.new("./results/urltest-part.ml").read, last_response.body

    destroy :urltest
  end

  def test_email
    create :emailtest

    get('/html/emailtest')
    assert last_response.ok?
    assert_equal File.new("./results/emailtest.ml").read, last_response.body

    get('/html/emailtest/1')
    assert last_response.ok?
    assert_equal File.new("./results/emailtest-part.ml").read, last_response.body

    destroy :emailtest
  end

  def test_tel
    create :teltest

    get('/html/teltest')
    assert last_response.ok?
    assert_equal File.new("./results/teltest.ml").read, last_response.body

    get('/html/teltest/1')
    assert last_response.ok?
    assert_equal File.new("./results/teltest-part.ml").read, last_response.body

    destroy :teltest
  end
end