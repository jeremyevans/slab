require 'sequel'

DB = Sequel.postgres(:user=>'slab', :password=>'slab')

Dir['./models/*'].each{|f| require f}
