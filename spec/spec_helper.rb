require File.join(File.dirname(__FILE__), '..', 'app.rb')
require 'rspec'
require 'rack/test'

set :environment, :test

def app
  Sinatra::Application
end

def fixture_path
  File.expand_path("../fixtures", __FILE__) + "/"
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end
