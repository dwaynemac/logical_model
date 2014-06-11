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

      def _save
        super
      end

      def _save_with_cache
        model_name = self.class.to_s.pluralize.underscore
        self.class.logger.debug "LogicalModel Log CACHE: Delete cache for #{model_name}\/#{self.id}-.*"
        Rails.cache.delete_matched(/#{model_name}\/#{self.id}-.*/)
        _save_without_cache
      end
      alias_method_chain :_save, :cache

      def _update(params)
        super
      end

      def _update_with_cache(params)
        model_name = self.class.to_s.pluralize.underscore
        self.class.logger.debug "LogicalModel Log CACHE: Delete cache for #{model_name}\/#{self.id}-.*"
        Rails.cache.delete_matched(/#{model_name}\/#{self.id}-.*/)
        _update_without_cache params
      end
      alias_method_chain :_update, :cache

      def _destroy
        super
      end

      def _destroy_with_cache
        model_name = self.class.to_s.pluralize.underscore
        self.class.logger.debug "LogicalModel Log CACHE: Delete cache for #{model_name}\/#{self.id}-.*"
        Rails.cache.delete_matched(/#{model_name}\/#{self.id}-.*/)
        _destroy_without_cache
      end
      alias_method_chain :_destroy, :cache      
    end

    module ClassMethods
      attr_accessor :expires_in

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
        # Generate key based on params
        cache_key = self.cache_key(id, params)
        # If there is a cached value return it
        Rails.cache.fetch(cache_key, :expires_in => self.expires_in || 10.minutes) do
          # Otherwise continue with regular find
          self.logger.debug 'LogicalModel Log CACHE: Calling find without cache'
          find_without_cache(id, params)
        end
        
      end
      alias_method_chain :find, :cache

      def delete(id, params={})
        super(id, params)
      end

      def delete_with_cache(id, params = {})
        model_name = self.to_s.pluralize.underscore
        self.class.logger.debug "LogicalModel Log CACHE: Delete cache for #{model_name}\/#{id}-.*"
        Rails.cache.delete_matched(/#{model_name}\/#{id}-.*/)
        delete_without_cache(id, params)
      end
      alias_method_chain :delete, :cache

      def delete_multiple(ids, params={})
        super(ids, params)
      end

      def delete_multiple_with_cache(ids, params = {})
        model_name = self.to_s.pluralize.underscore
        self.class.logger.debug "LogicalModel Log CACHE: Delete cache for #{model_name}\/(#{ids.join('|')})-.*"
        Rails.cache.delete_matched(/#{model_name}\/(#{ids.join('|')})-.*/)
        delete_multiple_without_cache(ids, params)
      end
      alias_method_chain :delete_multiple, :cache
    end

  end
end
