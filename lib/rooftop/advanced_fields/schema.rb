module Rooftop
  module AdvancedFields
    module Schema

      def self.included(base)
        base.extend ClassMethods

      end

      module ClassMethods

        
        def advanced_fields_schema
          return @advanced_fields_schema if defined?(@advanced_fields_schema)

          @advanced_fields_schema = ::Rails.cache.fetch("/advanced_fields_schema/#{name}") do
            reload_advanced_fields_schema!
          end
        end

        def advanced_fields
          if Rooftop.configuration.advanced_options[:use_advanced_fields_schema] && !advanced_fields_schema.nil?
            advanced_fields_schema.collect {|fieldset| fieldset[:fields].collect {|field| field.merge!(fieldset: fieldset[:title])}}.flatten
          else
            []
          end
        end

        def reload_advanced_fields_schema!
          options_data = options_raw(collection_path)[:parsed_data][:data]
          # default to nil if there's no advanced fields schema. This will be the case for taxonomies,
          # which in all other respects can be treated like posts in our response handling.
          if options_data.is_a?(Hash)
            options_data.try(:[],:schema).try(:[],:properties).try(:[],:advanced_fields_schema).try(:compact)
          end

          # return nil implied here, which leaves advanced_fields_schema as nil
        end
      end

      def advanced_fields_schema
        self.class.advanced_fields_schema
      end

      def advanced_fields
        self.class.advanced_fields
      end

      def build_fields_from_schema
        # Build a fields attribute if one doesn't exist
        self.fields ||= Rooftop::Content::Collection.new({}, self, advanced_fields)
        # Get the field names which already exist on the object
        existing_field_names = fields.field_names
        advanced_fields.each do |field|
          # skip fields which already exist
          next if existing_field_names.include?(field[:name])
          # create a new field from the schema for those that don't
          self.fields << Rooftop::Content::Field.new(field)
        end
      end

    end
  end
end
