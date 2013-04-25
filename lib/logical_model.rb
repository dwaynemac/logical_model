require 'timeout'
require 'active_model'
require 'typhoeus'
require 'active_support/all' # todo migrate to yajl
require 'kaminari'

require 'logical_model/rest_actions'
require 'logical_model/ssl_support'
require 'logical_model/safe_log'
require 'logical_model/has_many_keys'
require 'logical_model/api_key'
require 'logical_model/attributes'

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

  include LogicalModel::Attributes
  include LogicalModel::RESTActions
  include LogicalModel::SslSupport
  include LogicalModel::ApiKey
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

  DEFAULT_TIMEOUT = 10000
  DEFAULT_RETRIES = 3

  def initialize(attributes={})
    self.attributes = attributes
  end

  class << self
    attr_accessor :host, :resource_path,
                  :timeout, :retries,
                  :json_root

    def timeout; @timeout ||= DEFAULT_TIMEOUT; end
    def retries; @retries ||= DEFAULT_RETRIES; end
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
