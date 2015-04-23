#html_test.rb
#unit testing for label-based basie files
require "sinatra"
require "test/unit"
require "rack/test"

require_relative '../lib/basie'
require_relative 'test_databases'

class LabelTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
  	Sinatra::Application
  end

  def setup
    $BS = Basie.new :name => "testdb"
    Basie.activate [:JSON, :HTML, :CSV]
    $BS.enable_full_access

    create [:righttest_label, :lefttest_label]
  end

  def teardown
    $BS.cleanup
    Basie.purge_interfaces
    app.reset!
  end

  #########################################################################
  ## TESTING LABEL DETECTION
  def test_label_detection
    assert !$BS.tables[:lefttest_label].settings[:use_label]
    assert $BS.tables[:righttest_label].settings[:use_label]
  end

  def test_bad_label
    assert_raise (Basie::NoLabelError){create :righttest_label_bad}
  end

  #########################################################################
  ## TESTING TABLE ACCESSORS

  def test_access_data_by_labels
    assert_equal({:hash=>"NCfF2hpltsLo", :rightcontent=>"nana"}, $BS.tables[:righttest_label].data_by_label('nana'))
  end

end
