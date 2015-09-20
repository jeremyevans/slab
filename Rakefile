require 'rake'

desc "Run the app with puma"
task :run do
  sh 'puma -e production config.ru'
end

namespace :db do
  desc "Create the user and database for Slab"
  task :create do
    sh 'echo "CREATE USER slab PASSWORD \'slab\'" | psql -U postgres'
    sh 'createdb -U postgres -O slab slab'
  end

  desc "Migrate the database up"
  task :up do
    sh 'sequel -m migrate "postgres:///?user=slab&password=slab"'
  end
end
