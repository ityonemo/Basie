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
  	assert_equal :id, cl.name
  	assert_equal :primary_key, cl.type
  end

  def test_column_primary_key_not_id
  	assert_raise(Basie::PrimaryKeyError){cl = Basie::Column.new("primary_key :blah")}
  end
end