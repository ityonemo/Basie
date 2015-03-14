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

  def test_input_form
    create :simpletest
      get('/htmlform/simpletest')

      assert last_response.ok?
      assert_equal File.new("./results/simpletest-form.ml").read, last_response.body
    destroy :simpletest
  end

  def test_input_form_with_data
    create :simpletest
    get('/htmlform/simpletest/1')

    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-with-data.ml").read, last_response.body

    destroy :simpletest
  end

  def test_input_form_complex
    create :complextest
      get('htmlform/complextest')

      assert last_response.ok?
      assert_equal File.new("./results/complextest-form.ml").read, last_response.body
    destroy :complextest
  end

  #####################################################################################333
  ##### PLAYING WITH CSS

  def reset_basie(params = {})
    Basie.purge_interpreters
    Basie.interpret :HTML, params
  end

###################################################################
## :table_id

  def test_table_id_suppression
    reset_basie :table_id => false
    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-no-table-id.ml").read, last_response.body

    destroy :simpletest
    reset_basie
  end

  def test_table_id_proc
    reset_basie :table_id => Proc.new {"substituted"}
    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-sub-table-id.ml").read, last_response.body

    destroy :simpletest
    reset_basie
  end

  def test_table_id_hash
    reset_basie :table_id => {:simpletest => "substituted"}
    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-sub-table-id.ml").read, last_response.body

    destroy :simpletest
    reset_basie
  end

###################################################################
## :header_class

  def test_header_suppression
    reset_basie :header_class => false

    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-no-header-class.ml").read, last_response.body

    destroy :simpletest

    reset_basie
  end


###################################################################
## :entry_id

  def test_entry_id_suppression
    reset_basie :entry_id => false
    create :simpletest

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-no-entry-id.ml").read, last_response.body

    destroy :simpletest
    reset_basie
  end

  def test_entry_id_proc
    reset_basie :entry_id => Proc.new {"substituted"}
    create :simpletest

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-sub-entry-id.ml").read, last_response.body

    destroy :simpletest
    reset_basie
  end

  def test_entry_id_hash
    reset_basie :entry_id => {:simpletest => "substituted"}
    create :simpletest

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-sub-entry-id.ml").read, last_response.body

    destroy :simpletest
    reset_basie
  end


###################################################################
## :form_id

  def test_form_id_suppression
    reset_basie :form_id => false
    create :simpletest

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-no-form-id.ml").read, last_response.body

    destroy :simpletest
    reset_basie
  end

  def test_form_id_proc
    reset_basie :form_id => Proc.new {"substituted"}
    create :simpletest

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-sub-form-id.ml").read, last_response.body

    destroy :simpletest
    reset_basie
  end

  def test_form_id_hash
    reset_basie :form_id => {:simpletest => "substituted"}
    create :simpletest

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-sub-form-id.ml").read, last_response.body

    destroy :simpletest
    reset_basie
  end


###################################################################
## :column_id

  def test_column_id_suppression
    reset_basie :column_id => false
    create :simpletest

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-no-column-id.ml").read, last_response.body

    destroy :simpletest
    reset_basie
  end

  def test_column_id_proc
    reset_basie :column_id => Proc.new {"substituted"}
    create :simpletest

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-sub-column-id.ml").read, last_response.body

    destroy :simpletest
    reset_basie
  end

  def test_column_id_hash
    reset_basie :column_id => {:test => "substituted"}
    create :simpletest

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-sub-column-id.ml").read, last_response.body

    destroy :simpletest
    reset_basie
  end

###################################################################
## :column_class

  def test_column_class_removal
    reset_basie :column_class => false

    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-no-column-class.ml").read, last_response.body

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-no-column-class.ml").read, last_response.body

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-no-column-class.ml").read, last_response.body

    destroy :simpletest
    reset_basie
  end  

  def test_column_class_proc
    reset_basie :column_class => Proc.new{|col| col == :id ? "substituted" : false}
    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-sub-column-class.ml").read, last_response.body

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-sub-column-class.ml").read, last_response.body

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-no-column-class.ml").read, last_response.body

    destroy :simpletest
    reset_basie
  end

  def test_column_class_hash
    reset_basie :column_class => {:id => "substituted", :test => false}
    create :simpletest

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-sub-column-class.ml").read, last_response.body

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-sub-column-class.ml").read, last_response.body

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-no-column-class.ml").read, last_response.body

    destroy :simpletest
    reset_basie
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