class LogicalModel
  module HasManyKeys

    def self.included(base)
      base.class.send(:attr_accessor, :use_ssl)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods

      def has_many_keys=(keys)
        @has_many_keys = keys
        attr_accessor *keys

        keys.each do |association|

          # return empty array or @association variable for each association
          define_method association do
            if instance_variable_get("@#{association}").blank?
              instance_variable_set("@#{association}", [])
            end

            instance_variable_get("@#{association}")
          end

          # this method loads the contact attributes recieved by logical model from the service
          define_method "#{association}=" do |params|
            collection = []
            params.each do |attr_params|
              if attr_params["_type"].present?
                attr_class = attr_params.delete("_type").to_s.constantize
              else
                attr_class = association.to_s.singularize.camelize.constantize
              end
              collection << attr_class.new(attr_params)
            end
            instance_variable_set("@#{association}", collection)
          end

          define_method "new_#{association.to_s.singularize}" do |attr_params|
            if attr_params["_type"].present?
              clazz = attr_params.delete(:_type).constantize
            else
              clazz = association.to_s.singularize.camelize.constantize
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
              else
                attr_class = association.to_s.singularize.camelize.constantize
              end
              array << attr_class.new(attr_params)
            end
            instance_variable_set("@#{association}", array)
          end
        end
      end

      def has_many_keys
        @has_many_keys
      end
    end
  end
end
