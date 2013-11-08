class LogicalModel
  module UrlHelper

    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    # adds following setters
    # - force_ssl
    # - set_resource_host
    # - set_resource_path
    #
    # add reader
    # - resource_uri
    module ClassMethods

      attr_accessor :host,
                    :resource_path,
                    :use_ssl

      # Will return path to resource
      # @param id [String] (nil)
      def resource_uri(id=nil)
        sufix  = (id.nil?)? "" : "/#{id}"
        "#{url_protocol_prefix}#{host}#{resource_path}#{sufix}"
      end

      # If called in class, will make al request through SSL.
      # @example
      #   class Client < LogicalModel
      #     force_ssl
      #     ...
      #   end
      def force_ssl
        @use_ssl = true
      end

      # @param new_host [String] resource host. Should NOT include protocol (http)
      # @param new_path [String] resource path in host
      def set_resource_url(new_host,new_path)
        @host = new_host
        @resource_path = new_path
      end

      def set_resource_host(new_host)
        @host = new_host
      end

      def set_resource_path(new_path)
        @resource_path = new_path
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

      # Returns true if ssl is recommended
      #
      # - requests to localhost -> true
      # - other -> false
      #
      # @return [Boolean]
      def ssl_recommended?
        (@host && @host =~ /localhost/)
      end

      # Requests done within the block will go to new path.
      #
      # @example
      #   @resource_path # '/comments'
      #   do_with_resource_path("users/#{@user_id}/#{@resource_path}"}/") do
      #     @resource_path # '/users/23/comments'
      #   end
      #
      # @param [String] new_path
      def do_with_resource_path(new_path)
        bkp_path = @resource_path
        @resource_path = new_path
        yield
        @resource_path = bkp_path
      end
    end

  end
end
