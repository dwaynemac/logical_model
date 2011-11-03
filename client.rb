require 'rubygems'
require 'bundler/setup'
require 'typhoeus'
require 'json'
require 'lib/logical_model'

class User < LogicalModel
  #class << self; attr_accessor :base_uri end

  #self.hydra = Typhoeus::Hydra.new
  self.use_ssl = false #(Rails.env=="production")

  self.resource_path = "/api/v1/users"
  self.attribute_keys = [:name, :email, :password, :bio]
  self.use_api_key = false
  #self.api_key_name = "token"
  #self.api_key = "8c330b5d70f86ebfa6497c901b299b79afc6d68c60df6df0bda0180d3777eb4a5528924ac96cf58a25e599b4110da3c4b690fa29263714ec6604b6cb2d943656"
  self.host  = "localhost:3000"
  self.log_path = "logs/development.log" 
  
  TIMEOUT = 5500 # miliseconds
  PER_PAGE = 9999

  # def self.find_by_name(name)
  #   response = Typhoeus::Request.get("#{base_uri}/api/v1/users/#{name}")
  #   if response.code == 200
  #     JSON.parse(response.body)["user"]
  #   elsif response.code == 404
  #     nil
  #   else
  #     raise response.body
  #   end
  # end

  # def self.create(attributes = {})
  #   response = Typhoeus::Request.post("#{base_uri}/api/v1/users", :body => attributes.to_json)
  #   if response.success?
  #     JSON.parse(response.body)["user"]
  #   else
  #     raise response.body
  #   end
  # end

  # def self.update(name, attributes)
  #   response = Typhoeus::Request.put("#{base_uri}/api/v1/users/#{name}", :body => attributes.to_json)
  #   if response.success?
  #     JSON.parse(response.body)["user"]
  #   else
  #     raise response.body
  #   end
  # end

  # def self.destroy(name)
  #   response = Typhoeus::Request.delete("#{base_uri}/api/v1/users/#{name}")
  #   response.success?
  # end

  # def self.login(name, password)
  #   response = Typhoeus::Request.post("#{base_uri}/api/v1/users/#{name}/sessions", :body => {:password => password}.to_json)
  #   if response.success?
  #     JSON.parse(response.body)["user"]
  #   elsif response.code == 400
  #     nil
  #   else
  #     raise response.body
  #   end
  # end
end