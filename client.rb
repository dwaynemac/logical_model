require 'rubygems'
require 'bundler/setup'
require 'typhoeus'
require 'json'
require './lib/logical_model'

class User < LogicalModel
  #class << self; attr_accessor :base_uri end

  self.hydra = Typhoeus::Hydra.new
  self.use_ssl = false #(Rails.env=="production")

  set_resource_url("localhost:3000","/api/v1/users")

  attribute :id
  attribute :name
  attribute :email
  attribute :password
  attribute :bio

  self.use_api_key = false
  #self.api_key_name = "token"
  #self.api_key = "8c330b5d70f86ebfa6497c901b299b79afc6d68c60df6df0bda0180d3777eb4a5528924ac96cf58a25e599b4110da3c4b690fa29263714ec6604b6cb2d943656"

  self.log_path = "logs/development.log"
  
  TIMEOUT = 5500 # miliseconds
  PER_PAGE = 9999

end
