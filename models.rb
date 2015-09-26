require 'sequel'
require 'securerandom'

unless defined?(Unreloader)
  require 'rack/unreloader'
  Unreloader = Rack::Unreloader.new(:reload=>false)
end

DB = Sequel.postgres(:user=>'slab', :password=>'slab')

Unreloader.require('models') do |f|
  Sequel::Model.send(:camelize, File.basename(f).sub(/\.rb\z/, ''))
end
