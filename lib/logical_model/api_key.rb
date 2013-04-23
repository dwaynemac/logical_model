class LogicalModel
  ##
  #
  #
  #
  #
  module ApiKey
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.send(:extend, ClassMethods)
    end

    module InstanceMethods

    end

    module ClassMethods
      attr_accessor :api_key, :api_key_name, :use_api_key

      # Set api_key
      # @param name [Symbol] name for api_key. Eg: app_key, token, etc.
      # @param value [String] value of key. Eg: 1o2u3hqkfd, secret, etc.
      #
      # @example
      #   class Client < LogicalModel
      #     set_api_key(:token, 'asdfasdf')
      #     ...
      #   end
      def set_api_key(name,value)
        @use_api_key = true
        @api_key_name = name
        @api_key = value
      end

      def use_api_key
        @use_api_key ||= false
      end

      # if needed will merge api_key into given hash
      # returns merged hash
      def merge_key(params = {})
        if self.use_api_key
          params.merge({self.api_key_name => self.api_key})
        else
          params
        end
      end

    end
  end
end