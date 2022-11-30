# encoding: UTF-8
source "http://rubygems.org"

gem "activemodel", '4.2.8'
gem "activesupport", '4.2.8'
gem "typhoeus", '0.6.4'
gem "ethon", "0.6.3"
gem "kaminari", '~> 1.2.1'

group :development, :test do
  #gem 'debugger'
  gem 'rake'
  gem 'activerecord'
  gem "shoulda"
  gem "bundler", ">= 1.2.2"
  gem "jeweler", "~> 1.6.4"
  #gem "rcov"
  gem "sqlite3"
  gem "sinatra", "~> 2.2.3"
  gem "json", '2.0.0'
  gem 'gemcutter'
	
  gem "rspec-rails"

  gem 'guard-rspec'
 
  # guard notifications on Mac OS X
  gem 'rb-fsevent', :require => false if RUBY_PLATFORM =~ /darwin/i
  gem 'growl', :require => false if RUBY_PLATFORM =~ /darwin/i

  # guard notifications on Linux
  gem 'rb-inotify', :require => false if RUBY_PLATFORM =~ /linux/i
  gem 'libnotify', :require => false if RUBY_PLATFORM =~ /linux/i
end
