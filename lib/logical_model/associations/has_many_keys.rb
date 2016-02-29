require 'string_helper'

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
            options[:class].is_a?(String) ? StringHelper.constantize(options[:class]) : options[:class]
          else
            StringHelper.to_class(key)
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
          # this method loads the associations attributes recieved by logical model from the service
          # it also allows loading instanciated objects
          define_method "#{association}=" do |params|
            collection = []
            params.each do |attr_params|
              if attr_params.is_a?(attr_class)
                # in this case we recieved instanciated objects
                collection << attr_params
              else
                # TODO if params has symbol key :_type this won't work
                clazz_name = attr_params['_type']
                attr_class = clazz_name.constantize unless clazz_name.blank?
                # in this case we recieved object attributes, we instanciate here
                collection << attr_class.new(attr_params)
              end
            end
            instance_variable_set("@#{association}", collection)
          end

          # Initialize instance of associated object
          define_method "new_#{StringHelper.singularize(association.to_s)}" do |attr_params|
            run_callbacks :new_nested do
              clazz_name = attr_params['_type']
              clazz = clazz_name.blank? ? attr_class  : clazz_name.constantize

              return unless clazz

              temp_object = clazz.new(attr_params.merge({"#{self.json_root}_id" => self.id}))
              eval(association.to_s) << temp_object
              temp_object
            end
          end

          # this method loads the contact attributes from the html form (using nested resources conventions)
          define_method "#{association}_attributes=" do |key_attributes|
            array = []
            key_attributes.each do |attr_params|
              clazz_name = attr_params['_type']
              clazz = clazz_name.blank? ? attr_class  : clazz_name.constantize
              
              attr_params.to_hash.symbolize_keys!
              array << clazz.new(attr_params)
            end
            instance_variable_set("@#{association}", array)
          end
        end
      end
    end
  end
end
