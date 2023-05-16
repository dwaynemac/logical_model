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
  # Recursively decodes Typhoeus encoded arrays in given Hash.
  #
  # @example Use directly in a Rails controller.
  #    class ApplicationController
  #       before_filter :decode_typhoeus_arrays
  #    end
  #
  # @author Dwayne Macgowan
  #
  def decode_typhoeus_arrays
    decode!(params)
  end

  # Recursively decodes Typhoeus encoded arrays in given Hash.
  #
  # @param hash [Hash]. This Hash will be modified!
  #
  # @return [Hash] Hash with properly decoded nested arrays.
  def decode!(hash)
    return hash unless is_hash?(hash)
    hash.each_pair do |key,value|
      if is_hash?(value)
        decode!(value)
        hash[key] = convert(value)
      end
    end
    hash
  end

  def decode(hash)
    decode!(hash.dup)
  end

  private

  def is_hash?(hash)
    hash.is_a?(Hash) || hash.is_a?(HashWithIndifferentAccess) || hash.is_a?(ActionController::Parameters)
  end

  # Checks if Hash is an Array encoded as a Hash.
  # Specifically will check for the Hash to have this
  # form: {'0' => v0, '1' => v1, .., 'n' => vN }
  #
  # @param hash [Hash]
  #
  # @return [Boolean] True if its a encoded Array, else false.
  def encoded?(hash)
    return false if hash.empty?
    if hash.keys.size > 1
      keys = hash.keys.map{|i| i.to_i if i.respond_to?(:to_i)}.sort
      keys == hash.keys.size.times.to_a
    else
      hash.keys.first =~ /0/
    end
  end

  # If the Hash is an array encoded by typhoeus an array is returned
  # else the self is returned
  #
  # @param hash [Hash] The Hash to convert into an Array.
  #
  # @return [Arraya/Hash]
  def convert(hash)
    if encoded?(hash)
      hash = hash.to_unsafe_h if hash.respond_to?(:to_unsafe_h)
      Hash[hash.sort_by{|k,v|k.to_i}].values
    else
      hash
    end
  end
end
