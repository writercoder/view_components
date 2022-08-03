# frozen_string_literal: true

require "test_helper"

class PropertiesDefinitionHelperTest < Minitest::Test
  include Primer::Responsive::PropertiesDefinitionHelper
  PROPERTY_IDENTIFIER_KEY = Primer::Responsive::PropertiesDefinitionHelper::PROPERTY_IDENTIFIER_KEY

  def props_definition_input
    {
      prop_a: prop(
        responsive: :no,
        type: Integer,
        default: 0
      ),

      prop_b: prop(type: String),

      responsive_prop_c: prop(
        allowed_values: [:a, :b],
        responsive: :yes,
        when_narrow: {
          allowed_values: [:n_a, :n_b],
          default: :n_a
        },
        when_regular: { default: :b },
        when_wide: { default: :a }
      ),

      prop_d: prop(
        allowed_values: [:a, :b],
        responsive: :transitional,
        default: :a,
        deprecation: {
          deprecated_values: [:aa, :bb],
          warn_message: "addtional deprecation message"
        }
      ),

      prop_ns: {
        deep_prop_a: prop(
          allowed_values: [:a, :b, :c],
          responsive: :yes
        ),

        deep_prop_b: prop(
          responsive: :transitional,
          allowed_values: [:a, :b, :c],
          default: :a,
          when_narrow: { default: :b },
          when_regular: { default: :b }
        )
      }
    }
  end

  def test_properties_definition_builder_creates_a_hash_of_properties_and_variants
    # arrange
    input = props_definition_input

    # act
    props_definition = properties_definition_builder(input)

    # assert
    prop_a = props_definition[:prop_a]
    assert_instance_of(Primer::Responsive::PropertyDefinition, prop_a)
    assert_equal(:prop_a, prop_a.name)
    assert_equal(false, prop_a.responsive?)
    assert_equal(true, prop_a.defined_default?)
    assert_equal(0, prop_a.default_value)
    assert_equal(false, prop_a.required?)

    prop_b = props_definition[:prop_b]
    assert_instance_of(Primer::Responsive::PropertyDefinition, prop_b)
    assert_equal(:prop_b, prop_b.name)
    assert_equal(false, prop_b.responsive?)
    assert_equal(false, prop_b.defined_default?)
    assert_equal(true, prop_b.required?)

    responsive_prop_c = props_definition[:responsive_prop_c]
    assert_instance_of(Primer::Responsive::PropertyDefinition, responsive_prop_c)
    assert_equal(:responsive_prop_c, responsive_prop_c.name)
    assert_equal(true, responsive_prop_c.responsive?)
    assert_equal(false, responsive_prop_c.defined_default?)
    assert_equal(false, responsive_prop_c.required?)
    assert_instance_of(
      Primer::Responsive::ResponsiveVariantPropertyDefinition,
      responsive_prop_c.responsive_variants[:when_narrow]
    )
    assert_equal(true, responsive_prop_c.defined_default?(:when_narrow))
    assert_equal(:n_a, responsive_prop_c.default_value(:when_narrow))
    assert_instance_of(
      Primer::Responsive::ResponsiveVariantPropertyDefinition,
      responsive_prop_c.responsive_variants[:when_regular]
    )
    assert_equal(true, responsive_prop_c.defined_default?(:when_regular))
    assert_equal(:b, responsive_prop_c.default_value(:when_regular))
    assert_instance_of(
      Primer::Responsive::ResponsiveVariantPropertyDefinition,
      responsive_prop_c.responsive_variants[:when_wide]
    )
    assert_equal(true, responsive_prop_c.defined_default?(:when_wide))
    assert_equal(:a, responsive_prop_c.default_value(:when_wide))

    transitional_prop_d = props_definition[:prop_d]
    assert_instance_of(Primer::Responsive::PropertyDefinition, transitional_prop_d)
    assert_equal(:prop_d, transitional_prop_d.name)
    assert_equal(true, transitional_prop_d.responsive?)
    assert_equal(true, transitional_prop_d.defined_default?)
    assert_equal(false, transitional_prop_d.required?)
    assert_equal(:a, transitional_prop_d.default_value)
    assert_instance_of(Primer::Responsive::PropertyDeprecation, transitional_prop_d.deprecation)
    assert_equal(true, transitional_prop_d.deprecated_value?(:aa))
    assert(
      transitional_prop_d
      .deprecation_warn_message(:aa)
      .include?(
        input[:prop_d][PROPERTY_IDENTIFIER_KEY][:deprecation][:warn_message]
      )
    )

    namespace = props_definition[:prop_ns]
    assert_kind_of(Hash, namespace)

    nested_deep_prop_a = namespace[:deep_prop_a]
    assert_instance_of(Primer::Responsive::PropertyDefinition, nested_deep_prop_a)
    assert(nested_deep_prop_a.responsive?(:yes))

    nested_deep_prop_b = namespace[:deep_prop_b]
    assert_instance_of(Primer::Responsive::PropertyDefinition, nested_deep_prop_b)
    assert(nested_deep_prop_b.responsive?(:transitional))
  end

  def test_normalize_property_values_sets_default_to_missing_values
    # arrange
    props_definition = properties_definition_builder(
      prop_a: prop(
        type: String,
        default: "default value"
      ),
      prop_b: prop(
        type: Integer,
        default: 100
      )
    )
    values = {
      prop_b: -1
    }

    # act
    normalized_values = normalize_property_values!(
      properties_definition: props_definition,
      property_values: values.deep_dup,
      fallback_to_default: true
    )

    # assert
    assert_equal(props_definition[:prop_a].default_value, normalized_values[:prop_a])
    assert_equal(values[:prop_b], normalized_values[:prop_b])
  end

  def test_normalize_property_values_spreads_fully_responsive_values
    # arrange
    props_definition = properties_definition_builder(
      prop_a: prop(
        responsive: :yes,
        allowed_values: [:a, :b, :c],
        default: :a
      )
    )
    values = {
      prop_a: :b
    }

    # act
    normalized_values = normalize_property_values!(
      properties_definition: props_definition,
      property_values: values.deep_dup,
      fallback_to_default: true
    )

    # assert
    assert_equal(false, normalized_values.key?(:prop_a), "Fully responsive props base values have to be moved into responsive variants")
    assert_equal(values[:prop_a], normalized_values[:when_narrow][:prop_a], "Fully responsive props base values have to be moved into responsive variants")
    assert_equal(values[:prop_a], normalized_values[:when_regular][:prop_a], "Fully responsive props base values have to be moved into responsive variants")
    assert_equal(false, normalized_values.fetch(:when_wide, {}).key?(:prop_a), "Optional responsive variants shouldn't be added implicitly")
  end

  def test_normalize_property_values_only_spreads_transitional_responsive_value_if_explicitly_set_into_variants
    # arrange
    props_definition = properties_definition_builder(
      prop_a: prop(
        responsive: :transitional,
        allowed_values: [:a, :b, :c],
        default: :a
      ),
      prop_b: prop(
        responsive: :transitional,
        allowed_values: [:ta, :tb, :tc],
        default: :tc,
        when_narrow: { default: :ta },
        when_regular: { default: :tb }
      )
    )
    values = {
      # setting as base value
      prop_a: :b,

      # setting as responsive value
      when_narrow: {
        prop_b: :tc
      }
    }

    # act
    normalized_values = normalize_property_values!(
      properties_definition: props_definition,
      property_values: values.deep_dup,
      fallback_to_default: true
    )

    # assert
    assert(normalized_values.key?(:prop_a), "Transitional responsive don't remove base values")
    assert_equal(values[:prop_a], normalized_values[:prop_a])
    assert_equal(false, normalized_values.fetch(:when_narrow, {}).key?(:prop_a), "Transitional responsive variants shouldn't be added implicitly")

    assert_equal(values[:when_narrow][:prop_b], normalized_values[:when_narrow][:prop_b])
    assert_equal(props_definition[:prop_b].default_value(:when_regular), normalized_values[:when_regular][:prop_b])
  end

  def test_normalize_property_values_uses_base_default_value_for_responsive_value_unless_responsive_variants_are_present_in_the_values
    # arrange
    props_definition = properties_definition_builder(
      prop_a: prop(
        responsive: :transitional,
        allowed_values: [:t_default, :t_narrow, :t_regular, :t_wide, :t_extra, :t_extra2],
        default: :t_default,
        when_narrow: { default: :t_narrow },
        when_regular: { default: :t_regular }
      )
    )
    # arrange: test cases
    values_empty = {}
    values_base_value = { prop_a: :t_extra }
    values_incomplete_variants = {
      when_narrow: { prop_a: :t_extra }
    }
    values_all_variants = {
      when_narrow: { prop_a: :t_extra },
      when_regular: { prop_a: :t_extra2 }
    }

    # act
    normalized_empty = normalize_property_values!(properties_definition: props_definition, property_values: values_empty.deep_dup)

    normalized_base_value = normalize_property_values!(properties_definition: props_definition, property_values: values_base_value.deep_dup)

    normalized_incomplete_variants = normalize_property_values!(properties_definition: props_definition, property_values: values_incomplete_variants.deep_dup)

    normalized_all_variants = normalize_property_values!(properties_definition: props_definition, property_values: values_all_variants.deep_dup)

    # assert
    assert_equal(:t_default, normalized_empty[:prop_a])
    assert_equal(false, normalized_empty.key?(:when_narrow))
    assert_equal(false, normalized_empty.key?(:when_regular))

    assert_equal(:t_extra, normalized_base_value[:prop_a])
    assert_equal(false, normalized_base_value.key?(:when_narrow))
    assert_equal(false, normalized_base_value.key?(:when_regular))

    assert_equal(false, normalized_incomplete_variants.key?(:prop_a))
    assert_equal(true, normalized_incomplete_variants.key?(:when_narrow))
    assert_equal(:t_extra, normalized_incomplete_variants[:when_narrow][:prop_a])
    assert_equal(true, normalized_incomplete_variants.key?(:when_regular))
    assert_equal(:t_regular, normalized_incomplete_variants[:when_regular][:prop_a])

    assert_equal(false, normalized_all_variants.key?(:prop_a))
    assert_equal(true, normalized_all_variants.key?(:when_narrow))
    assert_equal(:t_extra, normalized_all_variants[:when_narrow][:prop_a])
    assert_equal(true, normalized_all_variants.key?(:when_regular))
    assert_equal(:t_extra2, normalized_all_variants[:when_regular][:prop_a])
  end

  def test_normalize_property_values_fallback_to_default_when_invalid_value_present
    # arrange
    props_definition = properties_definition_builder(
      prop_a: prop(
        responsive: :no,
        allowed_values: [:a, :b, :c],
        default: :a
      ),
      prop_r: prop(
        responsive: :yes,
        allowed_values: [:ra, :rb],
        when_narrow: {
          allowed_values: [:rna, :rnb],
          default: :rnb
        },
        when_regular: {
          allowed_values: [:rra, :rrb],
          default: :rra
        },
        when_wide: { default: :rb }
      ),
      prop_t: prop(
        responsive: :transitional,
        allowed_values: [:ta, :tb, :tc],
        default: :tc,
        when_narrow: { default: :ta },
        when_regular: { default: :tb }
      )
    )
    values = {
      prop_a: :invalid_value,
      when_narrow: {
        prop_r: :rra # this value is not available for narrow, only for regular
      },
      when_regular: {
        prop_r: :rc # invalid value
      },
      when_wide: {
        prop_r: :rna, # this value is not available for wide, only for narrow
        prop_t: :td # invalid value for undefined variant in transitional
      }
    }

    # act
    normalized_values = normalize_property_values!(
      properties_definition: props_definition,
      property_values: values.deep_dup,
      fallback_to_default: true
    )

    # assert
    assert_equal(:a, normalized_values[:prop_a], "Invalid value should fallback to default")

    assert_equal(props_definition[:prop_r].default_value(:when_narrow), normalized_values[:when_narrow][:prop_r])
    assert_equal(props_definition[:prop_r].default_value(:when_regular), normalized_values[:when_regular][:prop_r])
    assert_equal(props_definition[:prop_r].default_value(:when_wide), normalized_values[:when_wide][:prop_r])

    assert_equal(props_definition[:prop_t].default_value(:when_narrow), normalized_values[:when_narrow][:prop_t])
    assert_equal(props_definition[:prop_t].default_value(:when_regular), normalized_values[:when_regular][:prop_t])
    assert_equal(props_definition[:prop_t].default_value, normalized_values[:when_wide][:prop_t])
  end

  def test_normalize_property_values_with_deep_properties_definitions
    # arrange
    props_definition = properties_definition_builder(
      one_lvl_deep: {
        prop_no: prop(type: String, default: "default value"),
        prop_responsive: prop(
          responsive: :yes,
          allowed_values: [:a, :b, :c],
          when_narrow: { default: :a },
          when_regular: { default: :b }
        ),
        prop_transitional: prop(
          responsive: :transitional,
          type: Numeric,
          default: -1
        )
      },
      multiple_lvls_deep: {
        level_a: {
          level_a_a: {
            prop_no: prop(type: String, default: "default value"),
            prop_responsive: prop(
              responsive: :yes,
              allowed_values: [:a, :b, :c],
              when_narrow: { default: :a },
              when_regular: { default: :b }
            ),
            prop_transitional: prop(
              responsive: :transitional,
              type: Numeric,
              default: -1
            )
          },
          level_a_b: prop(
            type: Integer,
            default: 100
          )
        },
        level_b: {
          prop_no: prop(type: String, default: "default value"),
          prop_responsive: prop(
            responsive: :yes,
            allowed_values: [:a, :b, :c],
            when_narrow: { default: :a },
            when_regular: { default: :b }
          ),
          prop_transitional: prop(
            responsive: :transitional,
            type: Numeric,
            default: -1
          )
        }
      }
    )
    values = {
      one_lvl_deep: {
        prop_no: :invalid_value,
        prop_transitional: :invalid_value
      },
      multiple_lvls_deep: {
        level_b: {
          prop_no: "valid value"
        }
      },
      when_narrow: {
        one_lvl_deep: { prop_responsive: :c },
        multiple_lvls_deep: {
          level_a: {
            level_a_a: { prop_responsive: :invalid_value}
          }
        }
      },
      when_regular: {
        one_lvl_deep: { prop_responsive: :invalid_value }
      }
    }

    # act
    normalized_values = normalize_property_values!(
      properties_definition: props_definition,
      property_values: values.deep_dup,
      fallback_to_default: true
    )

    # assert
    assert_equal(
      props_definition[:one_lvl_deep][:prop_no].default_value,
      normalized_values[:one_lvl_deep][:prop_no],
      "Invalid value should fallback to default"
    )
    assert_equal(
      props_definition[:one_lvl_deep][:prop_transitional].default_value,
      normalized_values[:one_lvl_deep][:prop_transitional],
      "Transitional property with invalid base value should fallback to default in a non-responsive fashion"
    )

    assert_equal(
      props_definition[:multiple_lvls_deep][:level_a][:level_a_a][:prop_no].default_value,
      normalized_values[:multiple_lvls_deep][:level_a][:level_a_a][:prop_no],
      "Invalid value will fallback to default even in nested properties"
    )
    assert_equal(
      props_definition[:multiple_lvls_deep][:level_a][:level_a_a][:prop_transitional].default_value,
      normalized_values[:multiple_lvls_deep][:level_a][:level_a_a][:prop_transitional],
      "Missing value for nested property is set to default"
    )
    assert_equal(
      values[:multiple_lvls_deep][:level_b][:prop_no],
      normalized_values[:multiple_lvls_deep][:level_b][:prop_no],
      "Valid value for nested property doesn't fallback to default"
    )
    assert_equal(
      props_definition[:multiple_lvls_deep][:level_b][:prop_transitional].default_value,
      normalized_values[:multiple_lvls_deep][:level_b][:prop_transitional],
      "Missing value for nested property is set to default"
    )

    assert_equal(
      values[:when_narrow][:one_lvl_deep][:prop_responsive],
      normalized_values[:when_narrow][:one_lvl_deep][:prop_responsive],
      "Valid responsive values don't fallback to default"
    )
    assert_equal(
      props_definition[:one_lvl_deep][:prop_responsive].default_value(:when_regular),
      normalized_values[:when_regular][:one_lvl_deep][:prop_responsive],
      "Invalid responsive value for nested property is normalized and set to default"
    )

    assert_equal(
      props_definition[:multiple_lvls_deep][:level_a][:level_a_a][:prop_responsive].default_value(:when_narrow),
      normalized_values[:when_narrow][:multiple_lvls_deep][:level_a][:level_a_a][:prop_responsive],
      "Invalid responsive value for nested property is normalized and set to default"
    )
    assert_equal(
      props_definition[:multiple_lvls_deep][:level_a][:level_a_a][:prop_responsive].default_value(:when_regular),
      normalized_values[:when_regular][:multiple_lvls_deep][:level_a][:level_a_a][:prop_responsive],
      "Missing responsive value for nested property is normalized and set to default"
    )

    assert_equal(
      props_definition[:multiple_lvls_deep][:level_b][:prop_responsive].default_value(:when_narrow),
      normalized_values[:when_narrow][:multiple_lvls_deep][:level_b][:prop_responsive],
      "Missing responsive value for nested property is normalized and set to default"
    )
    assert_equal(
      props_definition[:multiple_lvls_deep][:level_b][:prop_responsive].default_value(:when_regular),
      normalized_values[:when_regular][:multiple_lvls_deep][:level_b][:prop_responsive],
      "Missing responsive value for nested property is normalized and set to default"
    )
  end
end
