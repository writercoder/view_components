# frozen_string_literal: true

module Primer
  module Responsive
    # property space helper
    module PropertiesDefinitionHelper
      # NOTE: optional responsive variants are skipped
      # when calculating style classes and when validating missgin values
      RESPONSIVE_VARIANTS_MAP = {
        v_narrow: {
          style_class_modifier: "whenNarrow"
        },
        v_regular: {
          style_class_modifier: "whenRegular"
        },
        v_wide: {
          optional: true,
          style_class_modifier: "whenWide"
        }
      }.freeze

      RESPONSIVE_VARIANTS = RESPONSIVE_VARIANTS_MAP.keys.freeze
      REQUIRED_RESPONSIVE_VARIANTS = RESPONSIVE_VARIANTS_MAP.reject { |_, c| c[:optional] }.keys.freeze

      PROPERTY_IDENTIFIER_KEY = :__property_definition

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
          properties[name] = if definition.key?(PROPERTY_IDENTIFIER_KEY)
                               PropertyDefinition.new(
                                 name: "#{namespace}#{name}".to_sym,
                                 **definition[PROPERTY_IDENTIFIER_KEY]
                               )
                             else
                               properties_definition_builder(definition, name)
                             end
        end

        properties
      end

      # "flag" a property definition hash to be created as a proper PropertyDefinition
      # allowing for property namespacing
      def prop(property_definition = {})
        { PROPERTY_IDENTIFIER_KEY =>  property_definition }
      end

      # Validates each property in properties definition
      # If the property is exclusively responsive, the property value cannot be set as a base
      # value after the properties values are normalized with its default values
      #
      # @param properties_definition [Hash] definition of the properties available to the component
      # @param properties [Hash] names params of the components
      def validate_property_values(properties_definition:, property_values: {})
        properties_definition.each do |prop, possible_definition|
          unless possible_definition.is_a? PropertyDefinition
            validate_property_values(
              properties_definition: possible_definition,
              property_values: property_values.fetch(prop, {})
            )
            next
          end

          definition = possible_definition
          if definition.deprecated_value?(property_values[prop])
            definition.deprecation.deprecation_warn(property_values[prop])
            next
          end

          if definition.required? && !definition.responsive?(:yes)
            raise InvalidPropertyValueError, <<~MSG
              #{definition.invalid_value_base_message(property_values[prop])}
              Property value is required.
            MSG
          end

          # if definition.responsive == :yes && property_values.key?(prop)
          #   raise InvalidPropertyValueError, <<~MSG
          #     #{definition.invalid_value_base_message(property_values[prop])}
          #     Exclusively responsive property can't have value outside of responsive variants.
          #   MSG
          # end

          definition.validate_value(property_values[prop]) if property_values.key?(prop)
          RESPONSIVE_VARIANTS.each do |variant|
            next unless property_values.key?(variant)

            definition.validate_value(property_values[variant][prop], variant)
          end
        end
      end

      # if a value is missing from the property_values hash, it will be set to the default
      # value of the property definition, if it has a default.
      #
      # @param properties_definition [Hash] a map with the properties part of the component API
      # @param property_values [Hash] a map with the same structure of the definition holding component's current values
      # @param fallback_to_default [Boolean] if a value is not valid, it'll fallback to default if a default exists
      def fill_missing_values_with_default(properties_definition:, property_values: {}, fallback_to_default: false)
        properties_definition.each do |prop, possible_definition|
          unless possible_definition.is_a? PropertyDefinition
            property_values[prop] = fill_missing_values_with_default(
              properties_definition: possible_definition,
              property_values: property_values[prop] || {},
              fallback_to_default: fallback_to_default
            )
            next unless property_values[prop].is_a? Hash

            # moving responsive props to the base variants hash.
            # since this method is recursive, it'll create responsive variants
            # into every recursive hash and it needs to be bubbled up til
            # the "root" level hash
            RESPONSIVE_VARIANTS.each do |variant|
              next unless property_values[prop].key? variant

              property_values[variant] = {} unless property_values.key? variant
              property_values[variant][prop] = property_values[prop][variant]
            end

            # cleanup
            property_values[prop].except!(*RESPONSIVE_VARIANTS)
            property_values.delete(prop) if property_values[prop].empty?
            next
          end

          definition = possible_definition
          has_to_fallback = fallback_to_default && !definition.valid_value?(property_values[prop])
          next unless !property_values.key?(prop) || property_values[prop].nil? || has_to_fallback

          if definition.responsive?
            base_value = property_values[prop] if property_values.key? prop

            if definition.responsive?(:transitional) && !base_value.nil?
              property_values[prop] = definition.default_value
              next
            end

            RESPONSIVE_VARIANTS_MAP.each do |responsive_variant, responsive_variant_config|
              property_values[responsive_variant] = {} unless property_values.key? responsive_variant

              has_defined_variant = property_values[responsive_variant].key?(prop)
              responsive_value = has_defined_variant ? property_values[responsive_variant][prop] : base_value

              has_to_fallback ||= (fallback_to_default && !definition.valid_value?(responsive_value, responsive_variant))

              next if has_defined_variant && !has_to_fallback
              next if responsive_variant_config[:transitional] && !definition.defined_default?(responsive_variant)

              property_values[responsive_variant][prop] = responsive_value.nil? || has_to_fallback ? definition.default_value(responsive_variant) : responsive_value
            end
          elsif definition.defined_default?
            property_values[prop] = definition.default_value
          end
        end

        property_values
      end

      # if a value is missing from the property_values hash, it will be set to the default
      # value of the property definition, if it has a default.
      #
      # @param properties_definition [Hash] a map with the properties part of the component API
      # @param property_values [Hash] a map with the same structure of the definition holding component's current values
      # @param fallback_to_default [Boolean] if a value is not valid, it'll fallback to default if a default exists
      def normalize_property_values!(properties_definition:, property_values: {}, fallback_to_default: true)
        properties_definition.each do |prop, possible_definition|
          # normalize recursive property structure
          unless possible_definition.is_a? PropertyDefinition
            nested_property_values = property_values[prop] || {}
            RESPONSIVE_VARIANTS.each do |variant|
              next unless property_values.key? variant

              nested_property_values[variant] = property_values[variant][prop] if property_values[variant].key? prop
            end

            property_values[prop] = normalize_property_values!(
              properties_definition: possible_definition,
              property_values: nested_property_values,
              fallback_to_default: fallback_to_default
            )
            next unless property_values[prop].is_a? Hash

            # moving responsive props to the base responsive variants hash.
            # since this method is recursive, it'll create responsive variants
            # into every recursive hash and it needs to be bubbled up til
            # the "root" level hash
            RESPONSIVE_VARIANTS.each do |variant|
              next unless property_values[prop].key? variant

              property_values[variant] = {} unless property_values.key? variant
              property_values[variant][prop] = property_values[prop][variant]
            end

            # cleanup
            property_values[prop].except!(*RESPONSIVE_VARIANTS)
            property_values.delete(prop) if property_values[prop].empty?
            next
          end

          definition = possible_definition
          is_base_value_set = property_values.key?(prop)
          is_base_value_valid = definition.valid_value?(property_values[prop])
          has_responsive_values = any_defined_responsive_values?(property_values, prop)

          # transitional properties accept base value in a non-responsive fashion
          if definition.responsive?(:no) || (definition.responsive?(:transitional) && (is_base_value_set || definition.defined_default?) && !has_responsive_values)
            has_to_fallback = fallback_to_default && !is_base_value_valid
            property_values[prop] = definition.default_value if !is_base_value_set || has_to_fallback
            next
          end

          base_value = property_values[prop] if is_base_value_set
          property_values.delete(prop)

          # responsive variants will be added to spread the property value if they're set as base value
          RESPONSIVE_VARIANTS_MAP.each do |responsive_variant, responsive_variant_config|
            next if !property_values.key?(responsive_variant) && !definition.defined_default?(responsive_variant) && responsive_variant_config[:optional]

            property_values[responsive_variant] = {} unless property_values.key?(responsive_variant)

            has_defined_variant = property_values[responsive_variant].key?(prop)
            responsive_value = has_defined_variant ? property_values[responsive_variant][prop] : base_value
            is_responsive_value_valid = definition.valid_value?(responsive_value, responsive_variant)

            has_to_fallback = fallback_to_default && has_defined_variant && !is_responsive_value_valid
            property_values[responsive_variant][prop] = has_to_fallback || responsive_value.nil? ? definition.default_value(responsive_variant) : responsive_value
          end
        end

        property_values
      end

      def any_defined_responsive_values?(property_values, property_name)
        RESPONSIVE_VARIANTS_MAP.each_key do |responsive_variant|
          next unless property_values.key?(responsive_variant)
          return true if property_values[responsive_variant].key? property_name
        end

        false
      end

      def production_env?
        Rails.env.production?
      end
      module_function :production_env?
    end
  end
end
