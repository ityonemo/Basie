#test_them_all.rb

#tests all of our tests!

#testing basic basie objects
require_relative 'basie_test'
require_relative 'column_test'  
require_relative 'table_test'

#testing the various interpreter paths
require_relative 'json_test'  
require_relative 'html_test'  
require_relative 'csv_test'
require_relative 'post_test'

#testing more sophisticated features
require_relative 'hash_test'
require_relative 'input_test'