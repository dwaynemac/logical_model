class LogicalModel
  module ResponsesConfiguration

    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      # By default paginate and all will expect a response in the format:
      # { collection: [....], total: X }
      # Where collection contains an array of hashes that initialize the Object and
      # total contains the total number of elements in result (used for pagination)
      #
      # configure_index_response allows to change this defaults.
      # @example
      #    configure_index_response {collection: 'items', total: 'count'}
      #    This will expect response to have format: {items: [...], count: X}
      #
      # If collection is nil then array is expected at root and total will be ignored.
      # If total is nil it will be ignored
      def configure_index_response(hash_response)
        @collection_key = hash_response[:collection]
        @total_key      = hash_response[:total]
      end

      def collection_key
        @collection_key ||= 'collection'
      end

      def total_key
        @total_key ||= 'total'
      end
    end
  end
end