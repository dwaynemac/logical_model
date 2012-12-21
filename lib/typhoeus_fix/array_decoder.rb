#
# Typhoeus encodes arrays as hashes {'0' => v0, '1' => v1, .., 'n' => vN }
#
# To fix this in your rails server your should:
# in Gemfile:
#     gem 'logical_model', '~> 0.3.2'
#
# in application_controller.rb:
#
#    require 'typhoeus_fix/array_decoder'
#    class ApplicationController < ActionController::Base
#      include TyphoeusFix
#      before_filter :decode_typhoeus_arrays
#    end
#
module TyphoeusFix

  def decode_typhoeus_arrays
    deep_decode(params)
  end

  # Recursively decode Typhoeus encoded arrays
  def deep_decode(hash)
    return hash unless hash.is_a?(Hash)
    hash.each_pair do |key,value|
      if value.is_a?(Hash)
        deep_decode(value)
        hash[key] = value.decode_typhoeus_array
      end
    end
  end
end

# Add Hash#is_typhoeus_array? method
class Hash

  # Checks if hash is an Array encoded as a hash.
  # Specifically will check for the hash to have this form: {'0' => v0, '1' => v1, .., 'n' => vN }
  # @return [TrueClass]
  def im_an_array_typhoeus_encoded?
    return false if self.empty?
    #return if array is empty or the key is not a valid number
    return false if self.empty? || self.keys.first.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil
    self.keys.map {|k| k.to_i}.sort == (0...self.keys.size).map {|i| i}
  end

  # If the hash is an array encoded by typhoeus an array is returned
  # else the self is returned
  #
  # @see im_an_array_typhoeus_encoded?
  #
  # @return [Array/Hash]
  def decode_typhoeus_array
    if self.im_an_array_typhoeus_encoded?
      Hash[self.sort].values
    else
      self
    end
  end
end



# Rack Middleware to fix Typhoeus arrays encoding
# TODO this middleware didn't work, when fixed use it and remove filter from ApplicationController
=begin
module Typhoeus
  class ArraysDecoder
    def initialize(app)
      @app = app
    end

    def call(env)

      params = env["action_dispatch.request.parameters"]
      decode_typho_arrays(params)
      env["action_dispatch.request.parameters"] = params
      @app.call(env)
    end

    private

    # Recursively decode Typhoeus encoded arrays
    def decode_typho_arrays(hash)
      return hash unless hash.is_a?(Hash)
      hash.each_pair do |key,value|
        if value.is_a?(Hash)
          decode_typho_arrays(value)
          hash[key] = value.decode_typhoeus_array
        end
      end
    end
  end
end
=end