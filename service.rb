require 'rubygems'
require 'bundler/setup'
require 'active_record'
require 'sinatra'
require './models/user'

# setting up the environment
env_index = ARGV.index("-e")
env_arg = ARGV[env_index + 1] if env_index
env = env_arg || ENV["SINATRA_ENV"] || "development"
databases = YAML.load_file("config/database.yml")
ActiveRecord::Base.establish_connection(databases[env])

if env == "test"
  puts "starting in test mode"
  User.destroy_all
  User.create(:name => "paul", :email => "paul@pauldix.net", :bio => "rubyist")
end



# Simple RESTfull Service
# for LogicalModel Testing



# HTTP entry points
# get a user by name
get '/api/v1/users/:name' do
  user = User.find_by_name(params[:name])
  if user
    user.to_json
  else
    error 404, {:error => "user not found"}.to_json
  end
end

# create a new user
post '/api/v1/users' do
  begin
    user = User.new(params[:user])
    if user.save
      user.to_json
    else
      error 400, {:errors => user.errors}.to_json
    end
  rescue => e
    error 500, {:errors => e.message}.to_json
  end
end

# update an existing user
put '/api/v1/users/:name' do
  user = User.find_by_name(params[:name])
  if user
    begin
      if user.update_attributes(params[:user])
        user.to_json
      else
        error 400, user.errors.to_json
      end
    rescue => e
      error 400, e.message.to_json
    end
  else
    error 404, {:error => "user not found"}.to_json
  end
end

# destroy an existing user
delete '/api/v1/users/:name' do
  user = User.find_by_name(params[:name])
  if user
    user.destroy
    user.to_json
  else
    error 404, {:error => "user not found"}.to_json
  end
end
