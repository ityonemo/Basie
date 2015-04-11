#!/usr/bin/ruby

##test-them-all.rb
##test all the things.

#basics
require_relative 'basie_test'
require_relative 'table_test'
require_relative 'column_test'

#databasing sugar
require_relative 'hash_test'
require_relative 'foreign_test'
require_relative 'foreign_hash_test'
require_relative 'label_test'

#interfaces
require_relative 'json_test'
require_relative 'csv_test'
require_relative 'post_test'

#interfaces with html formatting
require_relative 'html_test'
require_relative 'html_format_test'

require_relative 'user_test'
require_relative 'user_format_test'