require 'rubygems'
require 'bacon'

$LOAD_PATH.unshift(File.expand_path File.dirname(__FILE__))
$LOAD_PATH.unshift(File.expand_path File.join(File.dirname(__FILE__), '..', 'lib'))
require 'active_record'
require 'simple_search'

Bacon.summary_on_exit
