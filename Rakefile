require 'rake'

desc "Run the app with puma"
task :run do
  sh 'puma -e production config.ru'
end

desc "Run the OCR processor"
task :ocr do
  sh "#{FileUtils::RUBY} ocr.rb"
end

desc "Tag the commits"
task :tag do
  sh <<SH
for x in `jot 19 0`; do git tag -d $x; done;
git log --pretty=oneline --no-color | \
awk '
BEGIN{i = 19;}
{
  i -=1;
  print "git tag -a -m Tag\\\\", i, i, $1, ";"}
' | sh;
SH
end

namespace :db do
  desc "Create the user and database for Slab"
  task :create do
    sh 'echo "CREATE USER slab PASSWORD \'slab\'" | psql -U postgres'
    sh 'createdb -U postgres -O slab slab'
  end

  desc "Drop the user and database for Slab"
  task :drop do
    sh 'dropdb -U postgres slab'
    sh 'dropuser -U postgres slab'
  end

  desc "Migrate the database up"
  task :up do
    sh 'sequel -m migrate "postgres:///?user=slab&password=slab"'
  end
end
