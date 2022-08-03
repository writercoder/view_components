# frozen_string_literal: true

module Primer
  module Responsive
    # style map helper
    module StyleClassMapHelper
      RESPONSIVE_VARIANTS_MAP = Primer::Responsive::PropertiesDefinitionHelper::RESPONSIVE_VARIANTS_MAP
      RESPONSIVE_VARIANTS = Primer::Responsive::PropertiesDefinitionHelper::RESPONSIVE_VARIANTS

      def add_responsive_variants(map, remove_initial: false)
        RESPONSIVE_VARIANTS_MAP.each do |responsive_variant, config|
          add_response_variant(map, responsive_variant, config[:style_class_modifier])
        end

        if remove_initial
          keys_to_be_removed = []
          map.each_key do |property_name|
            next if RESPONSIVE_VARIANTS_MAP.key? property_name

            keys_to_be_removed.push(property_name)
          end
          map.except!(*keys_to_be_removed)
        end
        map
      end

      def add_response_variant(map, responsive_variant, modifier)
        map[responsive_variant] = {} unless map.key?(responsive_variant)

        map_variant = map[responsive_variant]
        map.each do |property_name, value|
          next if RESPONSIVE_VARIANTS_MAP.key?(property_name)

          responsive_property_map = value.is_a?(Hash) ? build_responsive_variant(value, modifier) : derive_class_variant(value, modifier)
          map_variant[property_name] = responsive_property_map
        end
      end

      def build_responsive_variant(map, modifier)
        responsive_map = {}
        map.each do |key, value|
          responsive_map[key] = value.is_a?(Hash) ? build_responsive_variant(value, modifier) : derive_class_variant(value, modifier)
        end
        responsive_map
      end

      def derive_class_variant(class_name, modifier)
        "#{class_name}-#{modifier}"
      end

      # Derive an applied map from the current properties values.
      # NOTE: This method doesn't take in consideration any property definition, so to get the default classes, 
      #       make sure to fill the values with defaults before calling this method.
      #
      # @param map [Hash] a style class map with classes value-dependent
      # @param property_values [Hash] a hash with the current property values of the component
      def apply_values_to_style_map(map, property_values)
        applied_map = {}
        property_values.each do |property_name, value|
          next if RESPONSIVE_VARIANTS_MAP.key? property_name
          next unless map.key? property_name

          applied_map[property_name] = get_style_from_value(map[property_name], value)
        end

        if responsive_variants?(map)
          applied_responsive_map = apply_responsive_map(map, property_values)
          applied_map.merge! applied_responsive_map
        end

        applied_map
      end

      def apply_responsive_map(map, property_values)
        applied_map = {}

        RESPONSIVE_VARIANTS_MAP.each do |responsive_variant, variant_config|
          next unless map.key? responsive_variant

          responsive_map = map[responsive_variant]
          responsive_map.each do |property_name, property_map|
            if property_values.key?(responsive_variant) && property_values[responsive_variant].key?(property_name)
              value = property_values[responsive_variant][property_name]
            elsif property_values.key? property_name
              next if variant_config[:optional]

              value = property_values[property_name]
            else
              next
            end

            applied_style = get_style_from_value(property_map, value)

            applied_map[property_name] = if applied_map.key? property_name
                                           merge_class_styles(applied_map[property_name], applied_style)
                                         else
                                           applied_map[property_name] = applied_style
                                         end
          end
        end

        applied_map
      end

      def merge_class_styles(base_applied_styles, new_applied_styles)
        return "#{base_applied_styles} #{new_applied_styles}" if base_applied_styles.is_a?(String) && new_applied_styles.is_a?(String)

        return new_applied_styles unless base_applied_styles.is_a?(Hash) && new_applied_styles.is_a?(Hash)

        base_applied_styles.merge(new_applied_styles) do |_, base_value, new_value|
          merge_class_styles(base_value, new_value)
        end
      end

      # Matches the style map with the given value and returns the mapped class
      #
      # @param map [Hash] a map of the possible values of a property and its respective css class
      # @param value [Object] the value of the property. If it's a hash, the style is going to try to create a recursive applied map 
      def get_style_from_value(map, value)
        style_class = nil

        case value
        when Symbol, String, Numeric
          style_class = map[value] if map.key? value
        when true
          style_class = map if map.is_a? String
        when Hash
          style_class = {}
          value.each do |property_name, inner_value|
            next unless map.key?(property_name)

            style_class[property_name] = get_style_from_value(map[property_name], inner_value)
          end
        end

        style_class
      end

      # Checks if a hash has any responsive variants
      def responsive_variants?(hash)
        is_responsive = false
        RESPONSIVE_VARIANTS.each do |variant|
          next unless hash.key? variant

          is_responsive = true
          break
        end

        is_responsive
      end
    end
  end
end
