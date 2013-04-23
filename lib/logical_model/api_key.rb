class LogicalModel
  module ApiKey
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.send(:extend, ClassMethods)
    end

    module InstanceMethods

    end

    module ClassMethods
      attr_accessor :api_key, :api_key_name, :use_api_key

      def use_api_key
        @use_api_key ||= false
      end

      # if needed willmerge api_key into given hash
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