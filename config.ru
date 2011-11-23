require 'rack/contrib'

run Rack::File.new(File.dirname(__FILE__))
