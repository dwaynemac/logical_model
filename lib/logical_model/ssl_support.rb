class LogicalModel
  module SslSupport

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.send(:extend, ClassMethods)
    end

    module InstanceMethods

    end

    module ClassMethods

      attr_accessor :use_ssl

      # If called in class, will make al request through SSL.
      # @example
      #   class Client < LogicalModel
      #     force_ssl
      #     ...
      #   end
      def force_ssl
        @use_ssl = true
      end

      ##
      # Default use_ssl to ssl_recommend?
      # @return [Boolean]
      def use_ssl?
        @use_ssl ||= ssl_recommended?
      end

      # @return [String]
      def url_protocol_prefix
        (use_ssl?)? "https://" : "http://"
      end

      # Returns true if ssl is recommended according to environment.
      #
      # - production, staging -> true
      # - other -> false
      #
      # @return [Boolean]
      def ssl_recommended?
        ssl_recommended_environments = %W(production staging)
        ssl_recommended_environments.include?(defined?(Rails)? Rails.env : ENV['RACK_ENV'] )
      end
    end


  end
end
