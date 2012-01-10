module TyphoeusMocks

  # This stubs response of GET /resource
  #
  # @param [Hash] options
  # @option options [Array<Hash>] :collection
  # @option options [Integer] :total
  # @option options [String] :url
  # @option options [Integer] :status - HTTP status
  def mock_index(options={})
    req = Typhoeus::Request.any_instance
    response = mock(
      code: options[:status] || 200,
      body: {
        collection: options[:collection] || [],
        total: options[:total] || 0
      }.to_json,
      request: mock(url: options[:url] || "mockedurl"),
      time: 1234
    )
    req.stub(:on_complete).and_yield(response)
  end

  # This stubs response of GET /resource/:id
  #
  # @param [Hash] options
  # @option options [Array<Hash>] :attributes
  # @option options [String] :url
  # @option options [Integer] :status - HTTP status
  def mock_show(options={})
    req = Typhoeus::Request.any_instance
    response = mock(
      code: options[:status] || 200,
      body: options[:attributes].to_json,
      request: mock(url: options[:url] || "mockedurl"),
      time: 1234
    )
    req.stub(:on_complete).and_yield(response)
  end

  # Mocks a Typhoeus::Response
  # @param [Hash] options
  # @option [Integer] code - http response code. default: 200
  # @option [String] body - response body
  # @option [String] url - requested url
  # @return [Typhoeus::Response]
  def mock_response(options={})
    mock_response = Typhoeus::Response.new(
         :code => options[:code] || 200,
         :headers => "whatever",
         :time => 0.1,
         :body => options[:body])
    mock_response.stub!(:request).and_return(mock(:url => options[:url] || "mocked-url"))
    mock_response
  end

  # Mocks Typhoeus POST Request and returns a mocked_response
  # @param [Hash] options, see mock_response options.
  def mock_post_with(options={})
    Typhoeus::Request.stub!(:post).and_return(mock_response(options))
  end
end