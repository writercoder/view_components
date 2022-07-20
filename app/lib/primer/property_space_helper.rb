# frozen_string_literal: true

module Primer
  # property space helper
  module PropertySpaceHelper
    RESPONSIVE_VARIANTS = [:when_narrow, :when_regular, :when_wide].freeze

    # Validates each property in properties respects the property_space rules
    # If the property is responsive, the property value cannot be set as a base
    # value and have responsive variants at the same time
    #
    # @param properties [Hash] names params of the components
    # @param property_space [Hash] definition of the properties available to the component
    #       each property can be configured with the following hash
    #       {
    #         values: [], #list of all possible values
    #         type: Class, #class that the value has to be
    #         responsive: :denied|:optional|:required, # defaults to :denied when omitted
    #         [narrow|regular|wide]: { # variant specific definition
    #           values: [], #extra values only available in this responsive variant,
    #           default: <value> #
    #         },
    #         default: <value>
    #       }
    def validate_properties(property_space:, properties: {}, raise: true)
      properties.each do |key, value|
        #TODO: not implemented
      end
    end

    def fill_defaults(property_space:, properties: {})
      property_space.each do |prop, definition|
        next if properties.key?(prop) && !properties[prop].nil?

        if responsive_variant?(properties, prop)
          RESPONSIVE_VARIANTS.each do |responsive_variant|
            properties[responsive_variant] = {} unless properties.key? responsive_variant

            next if properties[responsive_variant].key? prop

            properties[responsive_variant][prop] = responsive_variant_default(definition, responsive_variant)
          end
        elsif definition.key? :default
          properties[prop] = definition[:default]
        end
      end

      properties
    end

    # Checks if there's any responsive variant in the properties hash
    #
    # @param properties [Hash]
    # @param property_name [Symbol]
    def responsive_variant?(properties, property_name)
      has_variant = false
      RESPONSIVE_VARIANTS.each do |variant|
        next unless properties.key? variant

        if properties[variant].key? property_name
          has_variant = true
          break
        end
      end

      has_variant
    end

    def responsive_variant_default(definition, responsive_variant)
      default_value = nil
      if definition.key? responsive_variant
        default_value = definitionp[responsive_variant][:default] if definitionp[responsive_variant].key? :default
      elsif definition.key? :default
        default_value = definition[:default]
      end

      default_value
    end
  end
end
