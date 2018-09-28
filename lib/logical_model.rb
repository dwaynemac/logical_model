require 'active_model'
require 'typhoeus'
require 'active_support/all' # todo migrate to yajl
require 'kaminari'

require 'logical_model/hydra'
require 'logical_model/responses_configuration'
require 'logical_model/rest_actions'
require 'logical_model/url_helper'
require 'logical_model/safe_log'
require 'logical_model/associations'
require 'logical_model/api_key'
require 'logical_model/attributes'
require 'logical_model/cache'

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
#    set_resource_url "remote.server", "/api/remote/path"
#
#    attribute :id
#    attribute :attribute_a
#    attribute :attribute_b
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
  extend ActiveModel::Callbacks
  define_model_callbacks :create, :save, :update, :destroy, :initialize, :new_nested

  include LogicalModel::Hydra
  include LogicalModel::ResponsesConfiguration
  include LogicalModel::Attributes
  include LogicalModel::RESTActions
  include LogicalModel::UrlHelper
  include LogicalModel::ApiKey
  include LogicalModel::SafeLog
  include LogicalModel::Associations

  # include ActiveModel Modules that are usefull
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Serializers::JSON
  include ActiveModel::Validations
#  include ActiveModel::MassAssignmentSecurity


  self.include_root_in_json = false

  attr_accessor :last_response_code

  DEFAULT_TIMEOUT = 10000
  DEFAULT_RETRIES = 3

  def initialize(attributes={})
    self.attributes = attributes
  end

  def initialize_with_callback(attributes = {})
    run_callbacks :initialize do
      initialize_without_callback(attributes)
    end
  end
  alias_method_chain :initialize, :callback

  class << self
    attr_accessor :timeout, :retries,
                  :json_root

    def timeout; @timeout ||= DEFAULT_TIMEOUT; end
    def retries; @retries ||= DEFAULT_RETRIES; end
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
