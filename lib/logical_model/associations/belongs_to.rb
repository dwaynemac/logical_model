class LogicalModel
  module Associations
    module BelongsTo

      def self.included(base)
        base.send(:extend, ClassMethods)
      end

      module ClassMethods
        # @param key [String] association name
        # @param options [Hash]
        # @option options [String/Constant] class
        def belongs_to(key, options = {})
          attr_accessor "#{key}_id"
          attr_class = get_attr_class(key, options)

          define_method("#{key}=") do |param|
            if param.is_a?(Hash)
              param.stringify_keys!
              instance_variable_set("@#{key}_id", param['id']) if param['id']
              instance = attr_class.new(param)
            elsif param.is_a?(attr_class)
              instance_variable_set("@#{key}_id", param.id)
              instance = param
            else
              # ...
            end

            instance_variable_set("@#{key}",instance)
          end

          define_method(key) do
            instance = eval("@#{key}")
            if instance.nil?
              instance = attr_class.find(eval("#{key}_id"))
              instance_variable_set("@#{key}",instance)
            end
            instance
          end

          # TODO define_method("#{key}_attribute="){|param| ... }

          define_method "new_#{key}" do |param|
            attr_class

            return unless attr_class

            temp_object = attr_class.new(param.merge({"#{self.json_root}_id" => self.id}))
            eval(key.to_s) << temp_object
            temp_object
          end
        end

        private

        def get_attr_class(key, options)
          if options[:class]
            attr_class = options[:class].is_a?(String) ? options[:class].constantize : options[:class]
          else
            attr_class = key.to_s.singularize.camelize.constantize
          end
          attr_class
        end
      end
    end
    end
end