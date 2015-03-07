#basie_test.rb
#unit testing for the basie object

require "test/unit"
require "rack/test"
require_relative '../lib/basie'

class TableTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  #TEST CREATING A TABLE.  These methods should emanate from the basie object.

  def test_create_table_no_symbol_argument
    bs = Basie.new :name => "testdb"
    #should not create a blank table
    bs.connect do
      assert_raise(ArgumentError){bs.create "wrong input"}
    end
  end

  def test_create_table_unmatched_definition
    bs = Basie.new :name => "testdb"
    #create a blank table, with a primary key and a single element.
    bs.connect do
      assert_raise(ArgumentError){bs.create(:nofile, [])}
    end
  end

  def test_create_table_no_definition_file
    bs = Basie.new :name => "testdb"
    #create a blank table, with a primary key and a single element.
    bs.connect do
      assert_raise(Errno::ENOENT){bs.create :nofile}
    end
  end

  def test_create_blank_string_table
    bs = Basie.new :name => "testdb"
    #create a blank table, with a primary key and a single element.
    bs.connect do
      assert_raise(ArgumentError){bs.create(:testtable, "")}
    end
  end
end