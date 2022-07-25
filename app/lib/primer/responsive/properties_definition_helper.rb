# frozen_string_literal: true

module Primer
  module Responsive
    # property space helper
    module PropertiesDefinitionHelper
      # NOTE: optional responsive variants are skipped
      # when calculating style classes and when validating missgin values
      RESPONSIVE_VARIANTS_MAP = {
        when_narrow: {
          style_class_suffix: "whenNarrow"
        },
        when_regular: {
          style_class_suffix: "whenRegular"
        },
        when_wide: {
          optional: true,
          style_class_suffix: "whenWide"
        }
      }.freeze

      RESPONSIVE_VARIANTS = RESPONSIVE_VARIANTS_MAP.keys.freeze

      # Error raised when the a property definition declaration is invalid
      InvalidPropertyDefinitionError = Class.new(StandardError)

      # Error when an invalid/inexistent property is added to the properties hash of a component
      InvalidPropertyError = Class.new(StandardError)

      # Error result of validating a property value that doesn't comply with its definition
      InvalidPropertyValueError = Class.new(StandardError)

      def properties_definition_builder(all_properties_definition_hash = {}, namespace = "")
        namespace = "#{namespace}.".to_sym unless namespace.empty?

        properties = {}
        all_properties_definition_hash.each do |name, definition|
          properties[name] = if definition.key?(:__property_definition)
                               PropertyDefinition.new(
                                 name: "#{namespace}#{name}".to_sym,
                                 **definition[:__property_definition]
                               )
                             else
                               properties_definition_builder(definition, name)
                             end
        end

        properties
      end

      # flag a property definition hash to be created as a proper PropertyDefinition
      # allowing for property namespacing
      def prop(property_definition)
        { __property_definition: property_definition }
      end

      # Validates each property in properties respects the property_space rules
      # If the property is responsive, the property value cannot be set as a base
      # value and have responsive variants at the same time
      #
      # @param properties_definition [Hash] definition of the properties available to the component
      # @param properties [Hash] names params of the components
      def validate_property_values(properties_definition:, property_values: {})
        return if production_env?

        properties_definition.each do |prop, possible_definition|
          validate_property_values(possible_definition, property_values.fetch(prop, {})) unless possible_definition.is_a? PropertyDefinition

          definition = possible_definition
          if definition.deprecated_value?(property_values[prop])
            definition.deprecation.deprecation_warn(property_values[prop])
            next
          end

          if definition.responsive == :required && property_values.key?(prop)
            raise InvalidPropertyValueError, <<~MSG
              Invalid value for #{definition.name.inspect}: #{property_values[prop].inspect}
              Required responsive property can't have value outside of responsive variants.
            MSG
          end

          # if definition.responsive == :no
          #   next if definition.type.nil? && definition.allowed_values.nil?

          #   if definition.type.nil?
          #   elsif property_values[prop].is_a? definition.type
          #   end
          # end
        end

        return unless errors.empty?

        raise InvalidPropertyValueError, <<~MSG
          The following properties have invalid values: #{errors.inspect}
        MSG
      end

      # if a value is missing from the property_values hash, it will be set to the default
      # value of the property definition, if it has a default.
      #
      # @param properties_definition [Hash] a map with the properties part of the component API
      # @param property_values [Hash] a map with the same structure of the definition holding component's current values
      def fill_missing_values_with_default(properties_definition:, property_values: {})
        properties_definition.each do |prop, possible_definition|
          unless possible_definition.is_a? PropertyDefinition
            property_values[prop] = fill_missing_values_with_default(
              properties_definition: possible_definition,
              property_values: property_values[prop] || {}
            )
            next unless property_values[prop].is_a?(Hash)

            # moving responsive variants to the base variants
            property_values[prop].each do |key, value|
              next unless RESPONSIVE_VARIANTS.include? key

              property_values[key] = { prop => {} } unless property_values.key? key
              property_values[key][prop] = value
            end
            # NOTE: can't use excep! here because PVC is ruby 2.7
            # property_values[prop].delete_if { |key| RESPONSIVE_VARIANTS.include? key }
            property_values[prop].except!(RESPONSIVE_VARIANTS)
            next
          end

          next if property_values.key?(prop) && !property_values[prop].nil?

          definition = possible_definition
          if definition.responsive == :no
            property_values[prop] = definition.default_value if definition.defined_default?
          else
            base_value = property_values[prop] if property_values.key? prop

            RESPONSIVE_VARIANTS_MAP.each do |responsive_variant, responsive_variant_config|
              property_values[responsive_variant] = {} unless property_values.key? responsive_variant
              next if property_values[responsive_variant].key? prop
              next if responsive_variant_config[:optional] && !definition.defined_default?(responsive_variant)

              property_values[responsive_variant][prop] = base_value.nil? ? definition.default_value(responsive_variant) : base_value
            end
          end
        end

        property_values
      end

      def production_env?
        Rails.env.production?
      end
      module_function :production_env?
    end
  end
end
