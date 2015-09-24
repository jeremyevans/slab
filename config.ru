require 'rack/unreloader'
require 'logger'

dev = ENV['RACK_ENV'] == 'development'
Unreloader = Rack::Unreloader.new(:subclasses=>%w'Roda Sequel::Model',
  :logger=>Logger.new($stdout), :reload=>dev){Slab}

require './models'
Unreloader.require('slab.rb'){'Slab'}
run(dev ? Unreloader : Slab.freeze.app)
