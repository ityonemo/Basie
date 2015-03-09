#column_test.rb
#unit testing for the Basie::Column object

require "test/unit"
require "rack/test"
require_relative '../lib/basie'

class ColumnTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_column_blank
  	assert_raise(Basie::DefinitionError){cl = Basie::Column.new("  ")}
  end

  def test_column_comment
  	assert_raise(Basie::DefinitionError){cl = Basie::Column.new(" #this is just a comment ")}
  end

  def test_column_primary_key
  	cl = Basie::Column.new("primary_key :id")
  	assert_equal(cl.name, :id)
  	assert_equal(cl.type, :primary_key)
  end

  def test_column_primary_key_not_id
  	assert_raise(Basie::DefinitionError){cl = Basie::Column.new("primary_key :blah")}
  end

  def test_column_integer_default_hash
  	cl = Basie::Column.new("Integer :test")
  	assert_equal(cl.name, :test)
  	assert_equal(cl.type, :integer)
  	assert_equal(cl.params[:htag], :number)
  end

  def test_column_boolean_default_hash
  	cl = Basie::Column.new("boolean :test")
  	assert_equal(cl.name, :test)
  	assert_equal(cl.type, :boolean)
  	assert_equal(cl.params[:htag], :checkbox)
  end

  def test_column_integer_suppression
  	cl = Basie::Column.new("Integer :test 		#suppress")
  	assert_equal(cl.name, :test)
  	assert_equal(cl.type, :integer)
  	assert_equal(cl.params[:htag], :suppress)
  end

  def test_column_url_htag
  	cl = Basie::Column.new("String :test 		#url")
  	assert_equal(cl.name, :test)
  	assert_equal(cl.type, :varchar)
  	assert_equal(cl.params[:htag], :url)
  end

end