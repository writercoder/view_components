# frozen_string_literal: true

require "test_helper"

class ResponsiveComponentTest < Minitest::Test
  def test_properties_definition_class_method_creates_properties_for_component
    # arrange
    klass = Class.new(Primer::Alpha::ResponsiveComponent) do
      # act
      properties_definition(
        simple_prop: prop(
          allowed_values: [:a, :b, :c],
          default: :b
        ),
        responsive_prop: prop(
          responsive: :yes,
          type: Numeric,
          when_narrow: { default: 1 },
          when_regular: { default: 2 }
        )
      )
    end
    Object.send(:const_set, :ChildResponsiveComponent, klass)

    # assert
    simple_prop_definition = ChildResponsiveComponent.properties[:simple_prop]
    assert_instance_of(Primer::Responsive::PropertyDefinition, simple_prop_definition)
    assert_equal(:b, simple_prop_definition.default_value)

    responsive_prop_definition = ChildResponsiveComponent.properties[:responsive_prop]
    assert_instance_of(Primer::Responsive::PropertyDefinition, responsive_prop_definition)
    assert_instance_of(Primer::Responsive::ResponsiveVariantPropertyDefinition, responsive_prop_definition.responsive_variants[:when_narrow])
    assert_instance_of(Primer::Responsive::ResponsiveVariantPropertyDefinition, responsive_prop_definition.responsive_variants[:when_regular])
    assert_equal(1, responsive_prop_definition.default_value(:when_narrow))
    assert_equal(2, responsive_prop_definition.default_value(:when_regular))

    # teardown
    Object.send(:remove_const, :ChildResponsiveComponent)
  end

  def test_add_properties_definition_class_method_inherits_parent_props
    # arrange
    parent_klass = Class.new(Primer::Alpha::ResponsiveComponent) do
      properties_definition(
        parent_prop_a: prop(
          allowed_values: [:a, :b, :c],
          default: :b
        ),
        parent_prop_b: prop(
          responsive: :yes,
          type: String
        )
      )
    end
    Object.send(:const_set, :ParentResponsiveComponent, parent_klass)

    child_klass = Class.new(ParentResponsiveComponent) do
      # act
      add_properties_definition(
        parent_prop_a: prop(
          type: String,
          default: "overwriting property definition"
        ),
        child_prop: prop(
          responsive: :yes,
          type: Integer
        )
      )
    end
    Object.send(:const_set, :ChildResponsiveComponent, child_klass)

    # assert
    parent_prop_a = ChildResponsiveComponent.properties[:parent_prop_a]
    original_prop_a = ParentResponsiveComponent.properties[:parent_prop_a]

    parent_prop_b = ChildResponsiveComponent.properties[:parent_prop_b]
    original_prop_b = ParentResponsiveComponent.properties[:parent_prop_b]

    child_prop = ChildResponsiveComponent.properties[:child_prop]

    assert_instance_of(Primer::Responsive::PropertyDefinition, parent_prop_a)
    assert_instance_of(Primer::Responsive::PropertyDefinition, parent_prop_b)
    assert_instance_of(Primer::Responsive::PropertyDefinition, child_prop)

    refute_equal(original_prop_a, parent_prop_a, "Child properties with same name should overwrite parent's property definition")
    assert_equal(original_prop_b, parent_prop_b, "Parent's properties should be inherited unless overwritten by Child properties_definition")

    # teardown
    Object.send(:remove_const, :ParentResponsiveComponent)
    Object.send(:remove_const, :ChildResponsiveComponent)
  end
end
