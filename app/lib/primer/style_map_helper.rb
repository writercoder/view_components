# frozen_string_literal: true

module Primer
  # style map helper
  module StyleMapHelper
    RESPONSIVE_VARIANTS = {
      viewportNarrow: "-whenNarrow",
      viewportRegular: "-whenRegular",
      viewportWide: "-whenWide"
    }.freeze

    def add_responsive_variants(map)
      RESPONSIVE_VARIANTS.each do |key, value|
        add_response_variant(map, key, value)
      end

      map
    end

    def add_response_variant(map, responsive_variant, modifier)
      map[responsive_variant] = {} unless map.key?(responsive_variant)

      map_variant = map[responsive_variant]
      map.each do |key, value|
        responsive_property_map = value.is_a?(Hash) ? build_responsive_variant(value, modifier) : derive_class_variant(value, modifier)
        map_variant[key] = responsive_property_map
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

    def get_style_map(map, property, value)
      return "" unless map.key?(property)

      current_map = map[property]
      case value
      when Hash
        class_list = []
        value.each do |inner_prop, inner_value|
          class_list << get_style_map(current_map, inner_prop, inner_value)
        end
        class_list.compact.join(" ")
      when Symbol
        result = get_style_map_property(current_map, value)
        if result.is_a? Hash
          get_style_map(result, value, nil)
        else
          result
        end
      else
        if current_map.key?(:DEFAULT)
          get_style_map(map, property, current_map[:DEFAULT])
        else
          ""
        end
      end
    end

    def get_responsive_styles(map, property, value)
      return "" unless map.key?(property)

      current_map = map[property]
      return "" if current_map.blank?

      class_list = []
      current_map.each_key do |key|
        current_value = value.nil? ? nil : value[key]
        class_list << get_style_map_property(current_map[key], current_value)
      end
      class_list.compact.join(" ")
    end

    def get_style_map_property(map, value)
      if value.nil?
        return "" unless map.key?(:DEFAULT)

        map[map[:DEFAULT]]
      else
        map[value]
      end
    end
  end
end
