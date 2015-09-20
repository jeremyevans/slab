require 'rake'

namespace :db do
  desc "Create the user and database for Slab"
  task :create do
    sh 'echo "CREATE USER slab PASSWORD \'slab\'" | psql -U postgres'
    sh 'createdb -U postgres -O slab slab'
  end
end
