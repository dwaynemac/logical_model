# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: logical_model 0.6.4 ruby lib

Gem::Specification.new do |s|
  s.name = "logical_model"
  s.version = "0.7.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Dwayne Macgowan"]
  s.date = "2016-08-23"
  s.description = "LogicalModel allows to use a resource as a model. It is based on web presentation http://www.slideshare.net/ihower/serviceoriented-design-and-implement-with-rails3"
  s.email = "dwaynemac@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".travis.yml",
    "Gemfile",
    "Gemfile.lock",
    "Guardfile",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "client.rb",
    "config.ru",
    "config/application.rb",
    "config/database.yml",
    "db/development.sqlite3",
    "db/migrate/001_create_users.rb",
    "lib/logical_model.rb",
    "lib/logical_model/api_key.rb",
    "lib/logical_model/associations.rb",
    "lib/logical_model/associations/belongs_to.rb",
    "lib/logical_model/associations/has_many_keys.rb",
    "lib/logical_model/attributes.rb",
    "lib/logical_model/cache.rb",
    "lib/logical_model/hydra.rb",
    "lib/logical_model/responses_configuration.rb",
    "lib/logical_model/rest_actions.rb",
    "lib/logical_model/safe_log.rb",
    "lib/logical_model/url_helper.rb",
    "lib/string_helper.rb",
    "lib/typhoeus_fix/array_decoder.rb",
    "log/logical_model.log",
    "logical_model.gemspec",
    "models/user.rb",
    "spec/client_spec.rb",
    "spec/lib/logical_model/associations/has_many_keys_spec.rb",
    "spec/lib/logical_model/cache_spec.rb",
    "spec/lib/typhoeus_fix/array_decoder_spec.rb",
    "test/helper.rb",
    "test/test_logical_model.rb",
    "test/typhoeus_mocks.rb"
  ]
  s.homepage = "http://github.com/dwaynemac/logical_model"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.8"
  s.summary = "LogicalModel allows to use a resource as a model."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activemodel>, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_runtime_dependency(%q<typhoeus>, [">= 1.0.1"])
      s.add_runtime_dependency(%q<ethon>, [">= 0.8.0"])
      s.add_runtime_dependency(%q<kaminari>, ["~> 1.2.1"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<activerecord>, [">= 0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<bundler>, [">= 1.2.2"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      #s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<sqlite3>, [">= 0"])
      s.add_development_dependency(%q<sinatra>, ["~> 1.2.6"])
      s.add_development_dependency(%q<json>, [">= 0"])
      s.add_development_dependency(%q<gemcutter>, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>, [">= 0"])
      s.add_development_dependency(%q<libnotify>, [">= 0"])
    else
      s.add_dependency(%q<activemodel>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<typhoeus>, [">= 1.0.1"])
      s.add_dependency(%q<ethon>, [">= 0.8.0"])
      s.add_dependency(%q<kaminari>, ["~> 1.2.1"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<activerecord>, [">= 0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<bundler>, [">= 1.2.2"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      #s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<sqlite3-ruby>, [">= 0"])
      s.add_dependency(%q<sinatra>, ["~> 1.2.6"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<gemcutter>, [">= 0"])
      s.add_dependency(%q<rspec-rails>, [">= 0"])
      s.add_dependency(%q<libnotify>, [">= 0"])
    end
  else
    s.add_dependency(%q<activemodel>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<typhoeus>, [">= 1.0.1"])
    s.add_dependency(%q<ethon>, [">= 0.8.0"])
    s.add_dependency(%q<kaminari>, ["~> 1.2.1"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<activerecord>, [">= 0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<bundler>, [">= 1.2.2"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    #s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<sqlite3-ruby>, [">= 0"])
    s.add_dependency(%q<sinatra>, ["~> 1.2.6"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<gemcutter>, [">= 0"])
    s.add_dependency(%q<rspec-rails>, [">= 0"])
    s.add_dependency(%q<libnotify>, [">= 0"])
  end
end

