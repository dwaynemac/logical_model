require 'timeout'
require 'active_model'
require 'typhoeus'
require 'active_support/all' # todo migrate to yajl
require 'logger'
require 'kaminari'

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
#   json_root: TODO doc
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

  DEFAULT_TIMEOUT = 10000

  class << self
    attr_accessor :host, :hydra, :resource_path, :api_key, :api_key_name, :timeout,
                  :use_ssl, :use_api_key, :enable_delete_multiple,
                  :json_root, :log_path

    def timeout; @timeout ||= DEFAULT_TIMEOUT; end
    def use_ssl; @use_ssl ||= false; end
    def log_path; @log_path ||= "log/logical_model.log"; end
    def use_api_key; @use_api_key ||= false; end
    def delete_multiple_enabled?; @enable_delete_multiple ||= false; end

    def validates_associated(*associations)
      associations.each do |association|
        validates_each association do |record, attr, value|
          unless value.collect{ |r| r.nil? || r.valid? }.all?
            value.reject { |t| t.valid? }.each do |t|
              record.errors.add("", "#{t.class.name} #{t.errors.full_messages.to_sentence}")
            end
          end
        end
      end
    end

    # host eg: "127.0.0.1:3010"
    # resource_path eg: "/api/v1/people"
  end

  def json_root
    @json_root ||= self.class.to_s.underscore
  end

  def self.resource_uri(id=nil)
    prefix = (use_ssl)? "https://" : "http://"
    sufix  = (id.nil?)? "" : "/#{id}"
    "#{prefix}#{host}#{resource_path}#{sufix}"
  end

  def initialize(attributes={})
    self.attributes = attributes
  end

  def self.has_many_keys=(keys)
    @has_many_keys = keys
    attr_accessor *keys

    keys.each do |association|

      # return empty array or @association variable for each association
      define_method association do
        if instance_variable_get("@#{association}").blank?
          instance_variable_set("@#{association}", [])
        end

        instance_variable_get("@#{association}")
      end

      # this method loads the contact attributes recieved by logical model from the service
      define_method "#{association}=" do |params|
        collection = []
        params.each do |attr_params|
          if attr_params["_type"].present?
            attr_class = attr_params.delete("_type").to_s.constantize
          else
            attr_class = association.to_s.camelize.constantize
          end
          collection << attr_class.new(attr_params)
        end
        instance_variable_set("@#{association}", collection)
      end

      define_method "new_#{association.to_s.singularize}" do |attr_params|
        if attr_params["_type"].present?
          clazz = attr_params.delete(:_type).constantize
        else
          clazz = association.to_s.singularize.camelize.constantize
        end

        return unless clazz

        temp_object = clazz.new(attr_params.merge({"#{self.json_root}_id" => self.id}))
        eval(association.to_s) << temp_object
        temp_object
      end

      # this method loads the contact attributes from the html form (using nested resources conventions)
      define_method "#{association}_attributes=" do |key_attributes|
          array = []
          key_attributes.each do |attr_params|
            attr_params.to_hash.symbolize_keys!
            if attr_params["_type"].present?
              attr_class = attr_params.delete("_type").to_s.constantize
            else
              attr_class = association.to_s.singularize.camelize.constantize
            end
            array << attr_class.new(attr_params)
          end
          instance_variable_set("@#{association}", array)
      end
    end
  end

  def self.has_many_keys
    @has_many_keys
  end

  def attributes
    attrs = self.class.attribute_keys.inject(ActiveSupport::HashWithIndifferentAccess.new) do |result,key|
      result[key] = read_attribute_for_validation(key)
      result
    end

    unless self.class.has_many_keys.blank?
      self.class.has_many_keys.inject(attrs) do |result,key|
        result["#{key}_attributes"] = send(key).map {|a| a.attributes}
        result
      end
    end
    attrs.reject {|key, value| key == "_id" && value.blank?}
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
    begin
      error_message = ActiveSupport::JSON.decode(response.body)["message"]
    rescue => e
      error_message = "error"
    end
    msg = "LogicalModel Log: #{response.code} #{response.request.url} in #{response.time}s FAILED: #{error_message}"
    self.logger.warn(msg)
    self.logger.debug("LogicalModel Log RESPONSE: #{response.body}")
  end

  def log_failed(response)
    self.class.log_failed(response)
  end

  def self.logger
    Logger.new(self.log_path || "log/logical_model.log")
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
  #
  #  On error (400) a "errors" is expected.
  #  ============================================================================================================

  # Asynchronic Pagination
  #  This pagination won't block excecution waiting for result, pagination will be enqueued in Objectr#hydra.
  #
  # Parameters:
  #   @param options [Hash].
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
        collection = Kaminari.paginate_array(
                                             result_set[:collection],
                                             {
                                               :total_count=>result_set[:total],
                                               :limit => options[:per_page],
                                               :offset => options[:per_page] * ([options[:page], 1].max - 1)
                                             }
                                            )

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
    Timeout::timeout(self.timeout/1000) do
      self.hydra.run
    end
    result
  rescue Timeout::Error
    self.logger.warn("timeout")
    return nil
  end

  # Asynchronic Count
  #  This count won't block excecution waiting for result, count will be enqueued in Objectr#hydra.
  #
  # Parameters:
  #   @param options [Hash].
  #   Valid options are:
  #   @option options [Integer] :page - indicated what page to return. Defaults to 1.
  #   @option options [Integer] :per_page - indicates how many records to be returned per page. Defauls to 20
  #   @option options [Hash] all other options will be forwarded in :params to WebService
  #
  # @example 'Count bobs'
  #   Person.async_count(:when => {:name => 'bob'}}){|i| result = i}
  def self.async_count(options={})
    options[:page] = 1
    options[:per_page] = 1

    options = self.merge_key(options)

    request = Typhoeus::Request.new(resource_uri, :params => options)
    request.on_complete do |response|
      if response.code >= 200 && response.code < 400
        log_ok(response)

        result_set = self.from_json(response.body)

        yield result_set[:total]
      else
        log_failed(response)
      end
    end
    self.hydra.queue(request)
  end

  # synchronic count
  def self.count(options={})
    result = nil
    async_count(options){|i| result = i}
    Timeout::timeout(self.timeout/1000) do
      self.hydra.run
    end
    result
  rescue Timeout::Error
    self.logger.warn("timeout")
    return nil
  end

  # Asynchronic Find
  #  This find won't block excecution waiting for result, excecution will be enqueued in Objectr#hydra.
  #
  # Parameters:
  #   - id, id of object to find
  # @param [String/Integer] id
  # @param [Hash] params
  #
  # Usage:
  #   Person.async_find(params[:id])
  def self.async_find(id, params = {})
    params = self.merge_key(params)
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
  def self.find(id, params = {})
    result = nil
    async_find(id, params){|i| result = i}
    Timeout::timeout(self.timeout/1000) do
      self.hydra.run
    end
    result
  rescue Timeout::Error
    self.logger.warn("timeout")
    return nil
  end

  #
  # creates model.
  #
  # returns:
  # @return false if model invalid
  # @return nil if there was a connection problem
  # @return created model ID if successfull
  #
  # @example Usage:
  #   @person = Person.new(params[:person])
  #   @person.create( non_attribute_param: "value" )
  def create(params = {})
    return false unless valid?

    params = { self.json_root => self.attributes }.merge(params)
    params = self.class.merge_key(params)

    response = nil
    Timeout::timeout(self.class.timeout/1000) do
      response = Typhoeus::Request.post( self.class.resource_uri, :params => params, :timeout => self.class.timeout )
    end
    if response.code == 201
      log_ok(response)
      self.id = ActiveSupport::JSON.decode(response.body)["id"]
    elsif response.code == 400
      log_failed(response)
      ws_errors = ActiveSupport::JSON.decode(response.body)["errors"]
      ws_errors.each_key do |k|
        self.errors.add k, ws_errors[k]
      end
      return false
    else
      log_failed(response)
      return nil
    end
  rescue Timeout::Error
    self.class.logger.warn "timeout"
    return nil
  end

  # Updates Objects attributes, this will only send attributes passed as arguments
  #
  #
  # Returns false if Object#valid? is false.
  # Returns updated object if successfull.
  # Returns nil if update failed
  #
  # Usage:
  #   @person.update(params[:person])
  def update(attribute_params)

    self.attributes = attribute_params[self.json_root]

    return false unless valid?

    params = self.class.merge_key(attribute_params)

    e = Typhoeus::Easy.new

    e.url = self.class.resource_uri(_id)
    e.method = :put
    e.params = params

    response = nil
    Timeout::timeout(self.class.timeout/1000) do
      # using Typhoeus::Easy avoids PUT hang issue: https://github.com/dbalatero/typhoeus/issues/69
      e.perform
    end

    if e.response_code == 200
      self.class.logger.info("LogicalModel Log: #{e.response_code} #{e.url} in #{e.total_time_taken}s")
      self.class.logger.debug("LogicalModel Log RESPONSE: #{e.response_body}")
      return self
    else
      msg = "LogicalModel Log: #{e.response_code} #{e.url} in #{e.total_time_taken}s FAILED"
      self.class.logger.warn(msg)
      self.class.logger.debug("LogicalModel Log RESPONSE: #{e.response_body}")
      return nil
    end

  rescue Timeout::Error
    self.class.logger.warn("request timed out")
    return nil
  end

  # Saves Objects attributes
  #
  #
  # Returns false if Object#valid? is false.
  # Returns updated object if successfull.
  # Returns nil if update failed
  #
  # Usage:
  #   @person.save
  def save
    self.attributes = attributes

    return false unless valid?

    sending_params = self.attributes
    sending_params.delete(:id)

    params = { self.json_root => sending_params }
    params = self.class.merge_key(params)
    response = nil
    Timeout::timeout(self.class.timeout/1000) do
      response = Typhoeus::Request.put( self.class.resource_uri(id), :params => params, :timeout => self.class.timeout )
    end
    if response.code == 200
      log_ok(response)
      return self
    else
      log_failed(response)
      return nil
    end
  rescue Timeout::Error
    self.class.logger.warn "timeout"
    return nil
  end

  # Deletes Object#id
  #
  # Returns nil if delete failed
  #
  # @param [String] id - id of contact to be deleted
  # @param [Hash] params - other params to be sent to WS on request
  #
  # Usage:
  #   Person.delete(params[:id])
  def self.delete(id, params={})

    params = self.merge_key(params)

    response = nil
    Timeout::timeout(self.timeout/1000) do
      response = Typhoeus::Request.delete( self.resource_uri(id),
                                         :params => params,
                                         :timeout => self.timeout
                                       )
    end
    if response.code == 200
      log_ok(response)
      return self
    else
      log_failed(response)
      return nil
    end
  rescue Timeout::Error
    self.logger.warn "timeout"
    return nil
  end

  # Destroy object
  #
  # Usage:
  #   @person.destroy
  def destroy(params={})
    self.class.delete(self.id,params)
  end

  # Deletes all Objects matching given ids
  #
  # This method will make a DELETE request to resource_uri/destroy_multiple
  #
  # Returns nil if delete failed
  #
  # @param [Array] ids - ids of contacts to be deleted
  # @param [Hash] params - other params to be sent to WS on request
  #
  # Usage:
  #   Person.delete_multiple([1,2,4,5,6])
  def self.delete_multiple(ids, params={})
    raise "not-enabled" unless self.delete_multiple_enabled?

    params = self.merge_key(params)
    params = params.merge({:ids => ids})

    response = nil
    Timeout::timeout(self.timeout/1000) do
      response = Typhoeus::Request.delete( self.resource_uri+"/destroy_multiple",
                                           :params => params,
                                           :timeout => self.timeout
      )
    end
    if response.code == 200
      log_ok(response)
      return self
    else
      log_failed(response)
      return nil
    end
  rescue Timeout::Error
    self.logger.warn "timeout"
    return nil
  end

  def persisted?
    false
  end


  # Returns true if a record has not been persisted yet.
  #
  # Usage:
  # @person.new_record?
  def new_record?
    !self.persisted?
  end

end
