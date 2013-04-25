class LogicalModel
  module Attributes
    # TODO replace this module with ActvieAttr ?
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.send(:extend, ClassMethods)
    end

    module InstanceMethods

      def attributes=(attrs)
        sanitize_for_mass_assignment(attrs).each{|k,v| send("#{k}=",v) if respond_to?("#{k}=")}
      end

      def attributes
        attrs = self.class.attribute_keys.inject(ActiveSupport::HashWithIndifferentAccess.new) do |result,key|
          result[key] = read_attribute_for_validation(key)
          result
        end

        unless self.class.has_many_keys.blank?
          self.class.has_many_keys.inject(attrs) do |result,key|
            result["#{key}_attributes"] = send(key).map {|a| a.attributes}
            result
          end
        end
        attrs.reject {|key, value| key == "_id" && value.blank?}
      end
    end

    module ClassMethods

      # declares an attribute.
      # @param name [Symbol]
      # @example
      #     class Client < LogicalModel
      #       attribute :att_name
      #     end
      def attribute(name)
        @attribute_keys << name
        attr_accessor name
      end

      def attribute_keys=(keys)
        @attribute_keys = keys
        attr_accessor *keys
      end

      def attribute_keys
        @attribute_keys
      end
    end
  end
end