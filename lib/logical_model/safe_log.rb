require 'logger'

class LogicalModel
  module SafeLog

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

    end

    module ClassMethods
      attr_accessor :log_path

      def log_path
        @log_path ||= "log/logical_model.log"
      end

      def log_ok(response)
        self.logger.info("LogicalModel Log: #{response.code} #{mask_api_key(response.effective_url)} in #{response.time}s")
        self.logger.debug("LogicalModel Log RESPONSE: #{response.body}")
      end

      def log_failed(response)
        begin
          error_message = ActiveSupport::JSON.decode(response.body)["message"]
        rescue => e
          error_message = "error"
        end
        msg = "LogicalModel Log: #{response.code} #{mask_api_key(response.effective_url)} in #{response.time}s FAILED: #{error_message}"
        self.logger.warn(msg)
        self.logger.debug("LogicalModel Log RESPONSE: #{response.body}")
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

      # Filters api_key
      # @return [String]
      def mask_api_key(str)
        if use_api_key && str
          str = str.gsub(api_key,'[SECRET]')
        end
        str
      end

    end

  end
end
