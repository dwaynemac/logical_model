require 'timeout'
require 'active_model'
require 'typhoeus'
require 'active_support/all' # todo migrate to yajl
require 'kaminari'

require 'logical_model/rest_actions'
require 'logical_model/ssl_support'
require 'logical_model/safe_log'
require 'logical_model/has_many_keys'

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
#   json_root: Used to build parameters. Default: class name underscored
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

  include LogicalModel::RESTActions
  include LogicalModel::SslSupport
  include LogicalModel::SafeLog
  include LogicalModel::HasManyKeys

  # include ActiveModel Modules that are usefull
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Serializers::JSON
  include ActiveModel::Validations
  include ActiveModel::MassAssignmentSecurity

  extend ActiveModel::Callbacks
  define_model_callbacks :create, :save, :update, :destroy

  self.include_root_in_json = false

  attr_accessor :last_response_code

  def self.attribute_keys=(keys)
    @attribute_keys = keys
    attr_accessor *keys
  end

  def self.attribute_keys
    @attribute_keys
  end

  DEFAULT_TIMEOUT = 10000
  DEFAULT_RETRIES = 3

  class << self
    attr_accessor :host, :resource_path, :api_key, :api_key_name,
                  :timeout, :retries,
                  :use_api_key, :enable_delete_multiple,
                  :json_root

    def timeout; @timeout ||= DEFAULT_TIMEOUT; end
    def retries; @retries ||= DEFAULT_RETRIES; end
    def use_api_key; @use_api_key ||= false; end
    def delete_multiple_enabled?; @enable_delete_multiple ||= false; end

    def hydra
      @@hydra
    end

    def hydra=(hydra)
      @@hydra = hydra
    end

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
    sufix  = (id.nil?)? "" : "/#{id}"
    "#{url_protocol_prefix}#{host}#{resource_path}#{sufix}"
  end

  def initialize(attributes={})
    self.attributes = attributes
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

  ##
  # Will parse JSON string and initialize classes for all hashes in json_string[collection].
  #
  # @param json_string [JSON String] This JSON should have format: {collection: [...], total: X}
  #
  def self.from_json(json_string)
    parsed = ActiveSupport::JSON.decode(json_string)
    collection = parsed["collection"].map{|i|self.new(i)}
    return { :collection => collection, :total => parsed["total"].to_i }
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
