# encoding: UTF-8
source "http://rubygems.org"

gem "activemodel"
gem "activesupport"
gem "typhoeus", "~> 0.2.4"
gem "kaminari", '~> 0.13.0'

group :development, :test do
  gem 'activerecord' # for testapp
  gem "shoulda"
  gem "bundler", "~> 1.0.10"
  gem "jeweler", "~> 1.6.4"
  gem "rcov"
	gem "sqlite3-ruby"
	gem "sinatra", " ~> 1.2.6"
	gem "json"
	
  gem "rspec-rails"

  gem "guard-rspec"
 
  # guard notifications on Mac OS X
  gem 'rb-fsevent', :require => false if RUBY_PLATFORM =~ /darwin/i
  gem 'growl', :require => false if RUBY_PLATFORM =~ /darwin/i

  # guard notifications on Linux
  gem 'rb-inotify', :require => false if RUBY_PLATFORM =~ /linux/i
  gem 'libnotify', :require => false if RUBY_PLATFORM =~ /linux/i
end
