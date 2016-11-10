class LogicalModel
  module RESTActions

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.send(:extend, ClassMethods)
    end

    module InstanceMethods

      def create(params={})
        run_callbacks :save do
          run_callbacks :create do
            _create(params)
          end
        end
      end

      def save
        run_callbacks :save do
          run_callbacks new_record?? :create : :update do
            _save
          end
        end
      end

      def destroy(params={})
        run_callbacks :destroy do
          _destroy(params)
        end
      end

      # @param params [Hash] parameters to be sent to service
      def update(params)
        run_callbacks :save do
          run_callbacks :update do
            _update(params)
          end
        end

      end

      #
      # creates model.
      #
      # returns:
      # @return false if model invalid
      # @return nil if there was a connection problem
      # @return created model ID if successfull
      #
      # @example Usage:
      #   @person = Person.new(params[:person])
      #   @person.create( non_attribute_param: "value" )
      def _create(params = {})
        unless params[:ignore_validation]
          return false unless valid?
        end

        params = { self.json_root => self.attributes }.merge(params)
        params = self.class.merge_key(params)

        response = Typhoeus::Request.post( self.class.resource_uri, body: params, timeout: self.class.timeout )
        self.last_response_code = response.code
        if response.code == 201 || response.code == 202
          log_ok(response)
          if self.respond_to?('id=')
            self.id = ActiveSupport::JSON.decode(response.body)["id"]
          else
            true
          end
        elsif response.code == 400
          log_failed(response)
          ws_errors = ActiveSupport::JSON.decode(response.body)["errors"]
          ws_errors.each_key do |k|
            self.errors.add k, ws_errors[k]
          end
          return false
        else
          log_failed(response)
          return nil
        end
      end

      # Updates Objects attributes, this will only send attributes passed as arguments
      #
      #
      # Returns false if Object#valid? is false.
      # Returns updated object if successfull.
      # Returns nil if update failed
      #
      # Usage:
      #   @person.update(params[:person])
      def _update(params)

        self.attributes = params[self.json_root]

        unless params[:ignore_validation]
          return false unless valid?
        end

        params = self.class.merge_key(params)

        response = Typhoeus::Request.put( self.class.resource_uri(id),
                                          params: params,
                                          timeout: self.class.timeout )

        if response.code == 200
          log_ok(response)
          return self
        else
          log_failed(response)
          return nil
        end
      end

      # Saves Objects attributes
      #
      #
      # Returns false if Object#valid? is false.
      # Returns updated object if successfull.
      # Returns nil if update failed
      #
      # Usage:
      #   @person.save
      def _save
        self.attributes = attributes

        return false unless valid?

        sending_params = self.attributes
        sending_params.delete(:id)

        params = { self.json_root => sending_params }
        params = self.class.merge_key(params)
        response = Typhoeus::Request.put( self.class.resource_uri(id), params: params, timeout: self.class.timeout )
        if response.code == 200
          log_ok(response)
          return self
        else
          log_failed(response)
          return nil
        end
      end

      # Destroy object
      #
      # Usage:
      #   @person.destroy
      def _destroy(params={})
        self.class.delete(self.id,params)
      end

    end

    module ClassMethods

      attr_accessor :enable_delete_multiple

      # @param header [Hash]
      def set_default_headers(header)
        @headers = header
      end

      # User specified default headers
      # @return [Hash]
      def default_headers
        @headers
      end

      #  ============================================================================================================
      #  Following methods are API specific.
      #  They assume we are using a RESTfull API.
      #  for get, put, delete :id is expected
      #  for post, put attributes are excepted under class_name directly.
      #    eg. put( {:id => 1, :class_name => {:attr => "new value for attr"}} )
      #
      #  On error (400) a "errors" key is expected in response
      #  ============================================================================================================

      # @param options [Hash] will be forwarded to API
      def async_all(options={})
        options = self.merge_key(options)
        request = Typhoeus::Request.new(resource_uri, params: options, headers: default_headers)
        request.on_complete do |response|
          if response.code >= 200 && response.code < 400
            log_ok(response)

            result_set = self.from_json(response.body)
            collection = result_set[:collection]

            yield collection
          else
            log_failed(response)
          end
        end
        self.hydra.queue(request)
      end

      def all(options={})
        result = nil
        self.retries.times do
          begin
            async_all(options){|i| result = i}
            self.hydra.run
            break unless result.nil?
          end
        end
        result
      end

      # Asynchronic Pagination
      #  This pagination won't block excecution waiting for result, pagination will be enqueued in Objectr#hydra.
      #
      # Parameters:
      #   @param options [Hash].
      #   Valid options are:
      #   * :page - indicated what page to return. Defaults to 1.
      #   * :per_page - indicates how many records to be returned per page. Defauls to 20
      #   * all other options will be sent in :params to WebService
      #
      # Usage:
      #   Person.async_paginate(:page => params[:page]){|i| result = i}
      def async_paginate(options={})
        options[:page] ||= 1
        options[:per_page] ||= 20

        options = self.merge_key(options)

        request = Typhoeus::Request.new(resource_uri, params: options, headers: default_headers)
        request.on_complete do |response|
          if response.code >= 200 && response.code < 400
            log_ok(response)

            result_set = self.from_json(response.body)

            # this paginate is will_paginate's Array pagination
            collection = Kaminari.paginate_array(
                result_set[:collection],
                {
                    :total_count=>result_set[:total],
                    :limit => options[:per_page],
                    :offset => options[:per_page] * ([options[:page], 1].max - 1)
                }
            )

            yield collection
          else
            log_failed(response)
          end
        end
        self.hydra.queue(request)
      end

      #synchronic pagination
      def paginate(options={})
        result = nil
        self.retries.times do
          begin
            async_paginate(options){|i| result = i}
            self.hydra.run
            break unless result.nil?
          end
        end
        result
      end

      # Asynchronic Count
      #  This count won't block excecution waiting for result, count will be enqueued in Objectr#hydra.
      #
      # Parameters:
      #   @param options [Hash].
      #   Valid options are:
      #   @option options [Integer] :page - indicated what page to return. Defaults to 1.
      #   @option options [Integer] :per_page - indicates how many records to be returned per page. Defauls to 20
      #   @option options [Hash] all other options will be forwarded in :params to WebService
      #
      # @example 'Count bobs'
      #   Person.async_count(:when => {:name => 'bob'}}){|i| result = i}
      def async_count(options={})
        options[:page] = 1
        options[:per_page] = 1

        options = self.merge_key(options)

        request = Typhoeus::Request.new(resource_uri, params: options, headers: default_headers)
        request.on_complete do |response|
          if response.code >= 200 && response.code < 400
            log_ok(response)

            result_set = self.from_json(response.body)

            yield result_set[:total]
          else
            log_failed(response)
          end
        end
        self.hydra.queue(request)
      end

      # synchronic count
      def count(options={})
        result = nil
        async_count(options){|i| result = i}
        self.hydra.run
        result
      end

      # Asynchronic Find
      #  This find won't block excecution waiting for result, excecution will be enqueued in Objectr#hydra.
      #
      # Parameters:
      #   - id, id of object to find
      # @param [String/Integer] id
      # @param [Hash] params
      #
      # Usage:
      #   Person.async_find(params[:id])
      def async_find(id, params = {})
        params = self.merge_key(params)
        request = Typhoeus::Request.new( resource_uri(id), :params => params )

        request.on_complete do |response|
          if response.code >= 200 && response.code < 400
            log_ok(response)
            yield async_find_response(id, params, response.body), response.code
          else
            log_failed(response)
            yield nil, response.code
          end
        end

        self.hydra.queue(request)
      end

      def async_find_response(id, params, body)
        if body.blank?
          # if request failed failed unexpectedly we may get code 200 but empty body
          self.logger.warn("got response code 200 but empty body")
          return nil
        end

        self.new.from_json(body)
      end

      # synchronic find
      def find(id, params = {})
        result = nil
        self.retries.times do
          begin
            response_code = nil
            async_find(id, params) do |res,code|
              result = res
              response_code = code
            end
            self.hydra.run
            break unless result.nil? && (response_code != 404) # don't retry if response was 404
          end
        end
        result
      end

      # Deletes Object#id
      #
      # Returns nil if delete failed
      #
      # @param [String] id - id of contact to be deleted
      # @param [Hash] params - other params to be sent to WS on request
      #
      # Usage:
      #   Person.delete(params[:id])
      def delete(id, params={})

        params = self.merge_key(params)

        response = Typhoeus::Request.delete( self.resource_uri(id),
                                             params: params,
                                             timeout: self.timeout
        )
        if response.code == 200
          log_ok(response)
          return self
        else
          log_failed(response)
          return nil
        end
      end

      # Deletes all Objects matching given ids
      #
      # This method will make a DELETE request to resource_uri/destroy_multiple
      #
      # Returns nil if delete failed
      #
      # @param [Array] ids - ids of contacts to be deleted
      # @param [Hash] params - other params to be sent to WS on request
      #
      # Usage:
      #   Person.delete_multiple([1,2,4,5,6])
      def delete_multiple(ids, params={})
        raise "not-enabled" unless self.delete_multiple_enabled?

        params = self.merge_key(params)
        params = params.merge({:ids => ids})

        response = Typhoeus::Request.delete( self.resource_uri+"/destroy_multiple",
                                             params: params,
                                             timeout: self.timeout
        )
        if response.code == 200
          log_ok(response)
          return self
        else
          log_failed(response)
          return nil
        end
      end
    end
  end

  ##
  # Will parse JSON string and initialize classes for all hashes in json_string[collection_key].
  #
  # @param json_string [JSON String] This JSON should have format: {collection: [...], total: X}
  #
  def self.from_json(json_string)
    parsed_response = ActiveSupport::JSON.decode(json_string)
    parsed_collection = collection_key.nil?? parsed_response : parsed_response[collection_key]
    collection = parsed_collection.map{|i| self.new(i)}

    if total_key
      {collection: collection, total: parsed_response[total_key].to_i}
    else
      { collection: collection }
    end
  end

end
