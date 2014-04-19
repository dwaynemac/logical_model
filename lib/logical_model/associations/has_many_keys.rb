class LogicalModel
  module Associations
    module HasManyKeys

      def self.included(base)
        base.send(:extend, ClassMethods)
      end

      module ClassMethods

        # @param key [String] association name
        # @param options [Hash]
        # @option options [String/Constant] class
        def has_many(key, options = {})
          @has_many_keys ||= []
          @has_many_keys << key
          define_association_methods(key,get_attr_class(key,options))
        end

        # DEPRECATED!!!
        # Use has_many instead
        def has_many_keys=(keys)
          @has_many_keys = keys
          attr_accessor *keys

          keys.each do |association|
            define_association_methods(association,get_attr_class(association,{}))
          end
        end

        def has_many_keys
          @has_many_keys
        end
        
        protected

        def get_attr_class(key, options)
          if options[:class]
            options[:class].is_a?(String) ? options[:class].constantize : options[:class]
          else
            key.to_s.singularize.camelize.constantize
          end
        end

        def define_association_methods(association,attr_class)

          # Accessor
          # return empty array or @association variable for each association
          define_method association do
            if instance_variable_get("@#{association}").blank?
              instance_variable_set("@#{association}", [])
            end

            instance_variable_get("@#{association}")
          end

          # Setter
          # this method loads the contact attributes recieved by logical model from the service
          define_method "#{association}=" do |params|
            collection = []
            params.each do |attr_params|
              if attr_params["_type"].present?
                attr_class = attr_params.delete("_type").to_s.constantize
              end
              collection << attr_class.new(attr_params)
            end
            instance_variable_set("@#{association}", collection)
          end

          # Initialize instance of associated object
          define_method "new_#{association.to_s.singularize}" do |attr_params|
            if attr_params["_type"].present?
              clazz = attr_params.delete(:_type).constantize
            else
              clazz = attr_class
            end

            return unless clazz

            temp_object = clazz.new(attr_params.merge({"#{self.json_root}_id" => self.id}))
            eval(association.to_s) << temp_object
            temp_object
          end

          # this method loads the contact attributes from the html form (using nested resources conventions)
          define_method "#{association}_attributes=" do |key_attributes|
            array = []
            key_attributes.each do |attr_params|
              attr_params.to_hash.symbolize_keys!
              if attr_params["_type"].present?
                attr_class = attr_params.delete("_type").to_s.constantize
              end
              array << attr_class.new(attr_params)
            end
            instance_variable_set("@#{association}", array)
          end
        end
      end
    end
  end
end
