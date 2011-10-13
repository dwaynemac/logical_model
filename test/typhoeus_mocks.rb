module TyphoeusMocks

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