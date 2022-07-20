# frozen_string_literal: true

module Primer
  # style map helper
  module StyleClassMapHelper
    RESPONSIVE_VARIANTS_MAP = {
      when_narrow: "whenNarrow",
      when_regular: "whenRegular",
      when_wide: "whenWide"
    }.freeze
    RESPONSIVE_VARIANTS = RESPONSIVE_VARIANTS_MAP.keys.freeze

    def add_responsive_variants(map, remove_initial: true)
      RESPONSIVE_VARIANTS_MAP.each do |responsive_variant, value|
        add_response_variant(map, responsive_variant, value)
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

    def build_responsive_variant(hash, modifier)
      responsive_map = {}
      hash.each do |key, value|
        responsive_map[key] = derive_class_variant(value, modifier)
      end
      responsive_map
    end

    def derive_class_variant(class_name, modifier)
      "#{class_name}-#{modifier}"
    end

    # derive an applied map from the current properties values
    def apply_style_map(map, properties)
      applied_map = {}
      properties.each do |property_name, value|
        next if RESPONSIVE_VARIANTS_MAP.key? property_name
        next unless map.key? property_name

        applied_map[property_name] = get_style_from_value(map[property_name], value)
      end

      if responsive_variants?(map)
        applied_responsive_map = apply_responsive_map(map, properties)
        applied_map.merge! applied_responsive_map
      end

      applied_map
    end

    def apply_responsive_map(map, properties)
      {} unless responsive_variants?(properties)

      applied_map = {}

      RESPONSIVE_VARIANTS.each do |responsive_variant|
        next unless map.key? responsive_variant

        responsive_map = map[responsive_variant]

        responsive_map.each do |property_name, property_map|
          if properties.key?(responsive_variant) && properties[responsive_variant].key?(property_name)
            value = properties[responsive_variant][property_name]
          elsif properties.key? property_name
            value = properties[property_name]
          else
            next
          end

          style = get_style_from_value(responsive_map[property_name], value)

          if applied_map.key?(property_name)
            applied_map[property_name] += " #{style}"
          else
            applied_map[property_name] = style
          end
        end

        # if properties.key? responsive_variant
        #   if properties
        #   responsive_properties = properties[responsive_variant]
        # else
        #   responsive_properties = properties
        # end

        # responsive_properties.each do |property_name, value|
        #   next unless responsive_map.key? property_name

        #   style = get_style_from_value(responsive_map[property_name], value)

        #   if applied_map.key?(property_name)
        #     applied_map[property_name] += " #{style}"
        #   else
        #     applied_map[property_name] = style
        #   end
        # end
      end

      applied_map
    end

    def get_style_from_value(style_map, value)
      style_class = ""

      case value
      when Symbol
        style_class = style_map[value] if style_map.key? value
      when true
        style_class = style_map if style_map.is_a? String
      end

      style_class
    end

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
