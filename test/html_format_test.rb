#html_format_test.rb
#unit testing formatting for the Basie::HTMLInterpreter object
require "sinatra"
require "test/unit"
require "rack/test"
require "json"

require_relative '../lib/basie'
require_relative 'test_databases'

class HTMLFormatTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  #####################################################################################333
  ##### PLAYING WITH CSS

  def set_up(params = {})
    $BS = Basie.new :name => "testdb"
    Basie.purge_interfaces
    Basie.activate :HTML, params

    create :simpletest
  end

  def teardown
    $BS.cleanup
  	Basie.purge_interfaces
    app.reset!
  end

###################################################################
## :table_id

  def test_table_id_suppression
    set_up :table_id => false

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-no-table-id.ml").read, last_response.body
  end

  def test_table_id_proc
    set_up :table_id => Proc.new {"substituted"}

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-sub-table-id.ml").read, last_response.body
  end

  def test_table_id_hash
    set_up :table_id => {:simpletest => "substituted"}

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-sub-table-id.ml").read, last_response.body
  end

###################################################################
## :header_class

  def test_header_suppression
    set_up :header_class => false

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-no-header-class.ml").read, last_response.body
  end


###################################################################
## :entry_id

  def test_entry_id_suppression
    set_up :entry_id => false

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-no-entry-id.ml").read, last_response.body
  end

  def test_entry_id_proc
    set_up :entry_id => Proc.new {"substituted"}

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-sub-entry-id.ml").read, last_response.body
  end

  def test_entry_id_hash
    set_up :entry_id => {:simpletest => "substituted"}

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-sub-entry-id.ml").read, last_response.body
  end


###################################################################
## :form_id

  def test_form_id_suppression
    set_up :form_id => false

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-no-form-id.ml").read, last_response.body
  end

  def test_form_id_proc
    set_up :form_id => Proc.new {"substituted"}

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-sub-form-id.ml").read, last_response.body
  end

  def test_form_id_hash
    set_up :form_id => {:simpletest => "substituted"}

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-sub-form-id.ml").read, last_response.body
  end


###################################################################
## :column_id

  def test_column_id_suppression
    set_up :column_id => false

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-no-column-id.ml").read, last_response.body
  end

  def test_column_id_proc
    set_up :column_id => Proc.new {"substituted"}

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-sub-column-id.ml").read, last_response.body
  end

  def test_column_id_hash
    set_up :column_id => {:test => "substituted"}

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-sub-column-id.ml").read, last_response.body
  end

###################################################################
## :column_class

  def test_column_class_removal
    set_up :column_class => false

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-no-column-class.ml").read, last_response.body

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-no-column-class.ml").read, last_response.body

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-no-column-class.ml").read, last_response.body
  end  

  def test_column_class_proc
    set_up :column_class => Proc.new{|col| col == :id ? "substituted" : false}

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-sub-column-class.ml").read, last_response.body

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-sub-column-class.ml").read, last_response.body

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-no-column-class.ml").read, last_response.body
  end

  def test_column_class_hash
    set_up :column_class => {:id => "substituted", :test => false}

    get('/html/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-sub-column-class.ml").read, last_response.body

    get('/html/simpletest/1')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-part-sub-column-class.ml").read, last_response.body

    get('/htmlform/simpletest')
    assert last_response.ok?
    assert_equal File.new("./results/simpletest-form-no-column-class.ml").read, last_response.body
  end
end
