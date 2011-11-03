# encoding: utf-8

require 'rubygems'
gem 'activerecord', "=3.0.7"
require 'active_record'
require 'logger'
require 'bundler'
gem 'sqlite3'
require 'sqlite3'
require 'yaml'
#require 'active_support'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "logical_model"
  gem.homepage = "http://github.com/dwaynemac/logical_model"
  gem.license = "MIT"
  gem.summary = %Q{LogicalModel allows to use a resource as a model. }
  gem.description = %Q{LogicalModel allows to use a resource as a model. It is based on web presentation http://www.slideshare.net/ihower/serviceoriented-design-and-implement-with-rails3}
  gem.email = "dwaynemac@gmail.com"
  gem.authors = ["Dwayne Macgowan"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "logical_model #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Load the environment"
  task :environment do
    env = ENV["SINATRA_ENV"] || "development"
    databases = YAML.load_file("config/database.yml")
    ActiveRecord::Base.establish_connection(databases[env])
  end
namespace :db do
  desc "Migrate the database"
  task(:migrate => :environment) do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate("db/migrate")
  end
end
