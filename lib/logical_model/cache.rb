class LogicalModel
  module Cache

    def self.included(base)
      base.send(:extend, ClassMethods)
      base.send(:include, InstanceMethods)
      base.send(:after_initialize, :initialize_loaded_at)
    end

    module InstanceMethods
      attr_accessor :loaded_at

      def initialize_loaded_at
        self.loaded_at = Time.now
      end
    end

    # adds following setters
    # - 
    module ClassMethods
      # Will return key for cache
      # @param id [String] (nil)
      # @param params [Hash]
      def cache_key(id, params = {})
        model_name = self.to_s.pluralize.underscore
        params_hash = Digest::MD5.hexdigest(params.to_s)
        
        cache_key = "#{model_name}/#{id}-#{params_hash}"
      end

      def find(id, params={})
        super(id, params)
      end

      def find_with_cache(id, params = {})
        # generate key based on params
        cache_key = self.cache_key(id, params)
        # if there is a cached value return it
        # otherwise continue with regular find
        Rails.cache.fetch(cache_key, :expires_in => 1.minute) do
          puts 'calling find without cache'
          find_without_cache(id, params)
        end
        
      end
      alias_method_chain :find, :cache
    end

  end
end
