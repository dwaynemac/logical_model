require 'active_model'
require 'typhoeus'
require 'active_support' # todo migrate to yajl
require 'logger'

# Logical Model, not persistant on DB, works through API. (replaces ActiveResource)
#
#
# Configuration attributes:
#   host: Host of the WS. eg: "localhost:3000"
#   resource_path: Path of this resources. eg: "/api/resources"
#   attribute_keys: Attributes. eg: [:id, :attr_a, :attr_b]
#   use_ssl: will use https if true, http if false
#   use_api_key: set to true if api_key is needed to access resource
#   api_key_name: api key parameter name. eg: app_key
#   api_key: api_key. eg: "asd32fa4s4pdf35tr"
#   log_path: Path to log file. Will be ignored if using Rails.
#
# You may use validations such as validates_presence_of, etc.
#
# Usage:
#  class RemoteResource < LogicalModel
#    self.host = "http://remote.server"
#    self.resource_path = "/api/remote/path"
#    self.attribute_keys = [:id, :attribute_a, :attribute_b]
#
#    validates_presence_of :id
#  end
#
#  This enables:
#
#  RemoteResource.new(params[:remote_resource])
#  RemoteResource#create
#  RemoteResource.find(params[:id])
#  RemoteResource.paginate
#  RemoteResource#update(params[:remote_resouce])
#  RemoteResource.delete(params[:id])
#  RemoteResource#destroy
class LogicalModel

  # include ActiveModel Modules that are usefull
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Serializers::JSON
  include ActiveModel::Validations
  include ActiveModel::MassAssignmentSecurity

  self.include_root_in_json = false

  def self.attribute_keys=(keys)
    @attribute_keys = keys
    attr_accessor *keys
  end

  def self.attribute_keys
    @attribute_keys
  end

  class << self
    attr_accessor :host, :hydra, :resource_path, :use_ssl, :use_api_key, :api_key, :api_key_name, :log_path

    # host eg: "127.0.0.1:3010"
    # resource_path eg: "/api/v1/people"
  end

  def self.resource_uri(id=nil)
    prefix = (use_ssl)? "https://" : "http://"
    sufix  = (id.nil?)? "" : "/#{id}"
    "#{prefix}#{host}#{resource_path}#{sufix}"
  end

  def persisted?
    false
  end

  def initialize(attributes={})
    self.attributes = attributes
  end

  def attributes
    self.class.attribute_keys.inject(ActiveSupport::HashWithIndifferentAccess.new) do |result,key|
      result[key] = read_attribute_for_validation(key)
      result
    end
  end

  def attributes=(attrs)
    sanitize_for_mass_assignment(attrs).each{|k,v| send("#{k}=",v) if respond_to?("#{k}=")}
  end


  def self.from_json(json_string)
    parsed = ActiveSupport::JSON.decode(json_string)
    collection = parsed["collection"].map{|i|self.new(i)}
    return { :collection => collection, :total => parsed["total"].to_i }
  end

  def self.log_ok(response)
    self.logger.info("LogicalModel Log: #{response.code} #{response.request.url} in #{response.time}s")
    self.logger.debug("LogicalModel Log RESPONSE: #{response.body}")
  end

  def log_ok(response)
    self.class.log_ok(response)
  end

  def self.log_failed(response)
    # error_message = ActiveSupport::JSON.decode(response.body)["message"]
    error_message = "error"
    msg = "LogicalModel Log: #{response.code} #{response.request.url} in #{response.time}s FAILED: #{error_message}"
    self.logger.warn(msg)
    self.logger.debug("LogicalModel Log RESPONSE: #{response.body}")
  end

  def log_failed(response)
    self.class.log_failed(response)
  end

  def self.logger
    if defined?(Rails)
      Rails.logger
    else
      path = self.log_path.nil?? "log.log" : self.log_path
      Logger.new(path)
    end
  end

  # if needed willmerge api_key into given hash
  # returns merged hash
  def self.merge_key(params = {})
    if self.use_api_key
      params.merge({self.api_key_name => self.api_key})
    else
      params
    end
  end

  #  ============================================================================================================
  #  Following methods are API specific.
  #  They assume we are using a RESTfull API.
  #  for get, put, delete :id is expected
  #  for post, put attributes are excepted under class_name directly. eg. put( {:id => 1, :class_name => {:attr => "new value for attr"}} )
  #  ============================================================================================================

  # Asynchronic Pagination
  #  This pagination won't block excecution waiting for result, pagination will be enqueued in Objectr#hydra.
  #
  # Parameters:
  #   - options hash.
  #   Valid options are:
  #   * :page - indicated what page to return. Defaults to 1.
  #   * :per_page - indicates how many records to be returned per page. Defauls to 20
  #   * all other options will be sent in :params to WebService
  #
  # Usage:
  #   Person.async_paginate(:page => params[:page]){|i| result = i}
  def self.async_paginate(options={})
    options[:page] ||= 1
    options[:per_page] ||= 20

    options = self.merge_key(options)

    request = Typhoeus::Request.new(resource_uri, :params => options)
    request.on_complete do |response|
      if response.code >= 200 && response.code < 400
        log_ok(response)

        result_set = self.from_json(response.body)

        # this paginate is will_paginate's Array pagination
        collection = result_set[:collection].paginate(:page => options[:page],
                                                      :total_entries => result_set[:total],
                                                      :per_page => options[:per_page])

        yield collection
      else
        log_failed(response)
      end
    end
    self.hydra.queue(request)
  end

  #synchronic pagination
  def self.paginate(options={})
    result = nil
    async_paginate(options){|i| result = i}
    self.hydra.run
    result
  end

  # Asynchronic Find
  #  This find won't block excecution waiting for result, excecution will be enqueued in Objectr#hydra.
  #
  # Parameters:
  #   - id, id of object to find
  #
  # Usage:
  #   Person.async_find(params[:id])
  def self.async_find(id)
    params = self.merge_key
    request = Typhoeus::Request.new( resource_uri(id), :params => params )

    request.on_complete do |response|
      if response.code >= 200 && response.code < 400
        log_ok(response)
        yield self.new.from_json(response.body) # this from_json is defined in ActiveModel::Serializers::JSON
      else
        log_failed(response)
      end
    end

    self.hydra.queue(request)
  end

  # synchronic find
  def self.find(id)
    result = nil
    async_find(id){|i| result = i}
    self.hydra.run
    result
  end

  #
  # creates model.
  #
  # returns:
  #   - false if model invalid
  #   - nil if there was a connection problem
  #   - created model ID if successfull
  #
  # Usage:
  #   @person = Person.new(parmas[:person])
  #   @person.create
  def create
    return false unless valid?

    params = self.attributes
    params = self.merge_key(params)

    response = Typhoeus::Request.post( self.resource_uri, :params => params )
    if response.code == 201
      log_ok(response)
      self.id = ActiveSupport::JSON.decode(response.body)["id"]
    else
      log_failed(response)
      return nil
    end
  end

  # Updates Objects attributes.
  #
  # Returns false if Object#valid? is false.
  # Returns updated object if successfull.
  # Returns nil if update failed
  #
  # Usage:
  #   @person.update(params[:person])
  def update(attributes)

    self.attributes = attributes

    return false unless valid?

    params = { :self.class.underscore => self.attributes }
    params = self.merge_key(params)
    response = Typhoeus::Request.put( self.resource_uri(id), :params => params )
    if response.code == 200
      log_ok(response)
      return self
    else
      log_failed(response)
      return nil
    end
  end

  # Deletes Object#id
  #
  # Returns nil if delete failed
  #
  # Usage:
  #   Person.delete(params[:id])
  def self.delete(id)

    params = self.merge_key

    response = Typhoeus::Request.delete( self.resource_uri(id), :params => params )
    if response == 200
      log_ok(response)
      return self
    else
      log_failed(response)
      return nil
    end
  end

  # Destroy object
  #
  # Usage:
  #   @person.destroy
  def destroy
    self.class.delete(self.id)
  end

end
