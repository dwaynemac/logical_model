require 'logger'

class LogicalModel
  module SafeLog
    SECRET_PLACEHOLDER = "[SECRET]"

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.send(:extend, ClassMethods)
    end

    module InstanceMethods
      def log_ok(response)
        self.class.log_ok(response)
      end

      def log_failed(response)
        self.class.log_failed(response)
      end

      def sensitive_attributes
        self.class.sensitive_attributes
      end
    end

    module ClassMethods
      attr_accessor :log_path

      def log_path
        @log_path ||= "log/logical_model.log"
      end

      def log_ok(response)
        self.logger.info { "LogicalModel Log: #{response.code} #{mask_api_key(response.effective_url)} in #{response.time}s" }
        self.logger.debug { "LogicalModel Log RESPONSE: #{safe_body(response.body)}" }
      end

      def log_failed(response)
        begin
          error_message = ActiveSupport::JSON.decode(response.body)["message"]
        rescue => e
          error_message = "error"
        end
        msg = "LogicalModel Log: #{response.code} #{mask_api_key(response.effective_url)} in #{response.time}s FAILED: #{error_message}"
        self.logger.warn { msg }
        self.logger.debug { "LogicalModel Log RESPONSE: #{safe_body(response.body)}" }
      end

      def logger
        unless @logger
          @logger = Logger.new(self.log_path || "log/logical_model.log")
          if defined?(Rails)
            @logger.level = Rails.logger.level
          else
            @logger.level = Logger::DEBUG
          end
        end
        @logger
      end

      # declares an attribute that is sensitive and should be masked in logs
      # si no se llamó antes a attribute, lo declara
      # @param name [Symbol]
      # @example
      #     class Client < LogicalModel
      #       sensitive_attribute :att_name
      #     end
      def sensitive_attribute(name)
        if attribute_keys.blank? || !attribute_keys.include?(name)
          attribute(name)
        end
        @sensitive_attributes ||= []
        @sensitive_attributes << name
      end

      def sensitive_attributes
        @sensitive_attributes || []
      end

      def safe_body(body)
        parsed_response = ActiveSupport::JSON.decode(body)
        mask_sensitive_attributes(parsed_response).to_json
      rescue => e
        body
      end

      def mask_sensitive_attributes(parsed_response)
        if parsed_response.is_a?(Hash)
          parsed_response.each do |k,v|
            if sensitive_attributes.include?(k.to_sym)
              parsed_response[k] = SECRET_PLACEHOLDER
            else
              parsed_response[k] = mask_sensitive_attributes(v)
            end
          end
        elsif parsed_response.is_a?(Array)
          parsed_response.map! do |v|
            mask_sensitive_attributes(v)
          end
        end
        parsed_response
      end

      # Filters api_key
      # @return [String]
      def mask_api_key(str)
        if use_api_key && str
          str = str.gsub(api_key,SECRET_PLACEHOLDER)
        end
        str
      end

    end

  end
end
