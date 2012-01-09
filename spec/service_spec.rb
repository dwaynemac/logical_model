require File.dirname(__FILE__) + '/../service'

require 'rspec'
require 'rack/test'
require 'test/unit'
require 'sinatra'
require 'json'
#require 'rspec/interop/test'

set :environment, :test
Test::Unit::TestCase.send :include, Rack::Test::Methods

def app
  Sinatra::Application
end

RSpec.configure do |conf|                    #from Jason
  conf.include Rack::Test::Methods
end

describe "v1 service: " do
  before(:each) do
    User.delete_all
  end

  describe "get /api/v1/users" do
    before do
      User.create(name: "dwayne", email: "dwaynemac@gmail.com", password: "asdf", bio: "test")
      User.create(name: "2dwayne", email: "dw2aynemac@gmail.com", password: "a2sdf", bio: "te2st")
      get '/api/v1/users'
    end
    it { should respond_with :success }
    it "should send collection" do
      ActiveSupport::JSON.decode(last_response.body)['collection'].should_not be_nil
    end
    it "should send total items number" do
      AcriveSupport::JSON.decode(last_response.body)['total'].should == 2
    end
  end

  describe "RESTfull GET (on /api/v1/users/:id)" do
    context "for existing user" do
      before(:each) do
        User.create(
                      :name => "paul",
                      :email => "paul@pauldix.net",
                      :password => "strongpass",
                      :bio => "rubyist")
        get '/api/v1/users/paul'
      end
      it "should respond with 200" do
        last_response.status.should == 200      
      end
      it "should return user with id paul" do
        attributes = JSON.parse(last_response.body)["user"]
        attributes["name"].should == "paul"
      end
      it "should return users email" do
        attributes = JSON.parse(last_response.body)["user"]
        attributes["email"].should == "paul@pauldix.net"
      end
      it "should not return a user's password" do
        attributes = JSON.parse(last_response.body)["user"]
        attributes.should_not have_key("password")
      end
      it "should return user's bio" do
        attributes = JSON.parse(last_response.body)["user"]
        attributes["bio"].should == "rubyist"
      end      
    end
    context "for un-existing user" do
      before do
        get '/api/v1/users/foo'
      end
      it "should return not found" do
        last_response.status.should == 404
      end
    end
  end
  
  describe "RESTfull POST (on /api/v1/users) with attributes under resource name" do
    it "should create a user" do
      expect{post '/api/v1/users', :user => { :name => "trotter",
                              :email => "no spam",
                              :password => "whatever",
                              :bio => "southern belle" }}.to change{User.count}.by 1
      last_response.should be_ok
      
      get '/api/v1/users/trotter'
      attributes = JSON.parse(last_response.body)["user"]
      attributes["name"].should == "trotter"
      attributes["email"].should == "no spam"
      attributes["bio"].should == "southern belle"
    end
  end

  describe "RESTfull PUT (on /api/v1/users/:id) with params under resourcename" do
    it "should update a user" do
      User.create(
                    :name => "bryan",
                    :email => "no spam",
                    :password => "whatever",
                    :bio => "rspec master")
                    
      put '/api/v1/users/bryan', :user => {:bio => "testing freak"}
      
      last_response.status.should == 200
      
      get '/api/v1/users/bryan'
      attributes = JSON.parse(last_response.body)["user"]
      attributes["bio"].should == "testing freak"
    end
    context "when called with unexisting id" do
      before do
        put "/api/v1/users/no-existo"
      end
      it "should return not found" do
        last_response.status.should == 404
      end
    end
  end
  
  describe "RESTfull DELETE (on /api/v1/users/:id)" do
  it "should delete a user" do
    User.create(
                  :name => "francis",
                  :email => "no spam",
                  :password => "whatever",
                  :bio => "williamsburg hipster")
    
    expect{delete '/api/v1/users/francis'}.to change{User.count}.by -1
    
    last_response.should be_ok
    
    get '/api/v1/users/francis'
    last_response.status.should == 404
    end
  end
end
