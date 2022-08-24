# frozen_string_literal: true

require "test_helper"

class ResponsiveComponentTest < Minitest::Test
  def test_arguments_definition_class_method_creates_arguments_for_component
    # arrange
    klass = Class.new(Primer::Alpha::ResponsiveComponent) do
      # act
      arguments_definition(
        simple_prop: prop(
          allowed_values: [:a, :b, :c],
          default: :b
        ),
        responsive_prop: prop(
          responsive: :yes,
          type: Numeric,
          v_narrow: { default: 1 },
          v_regular: { default: 2 }
        )
      )
    end
    Object.send(:const_set, :ChildResponsiveComponent, klass)

    # assert
    simple_prop_definition = ChildResponsiveComponent.arguments[:simple_prop]
    assert_instance_of(Primer::Responsive::ArgumentDefinition, simple_prop_definition)
    assert_equal(:b, simple_prop_definition.default_value)

    responsive_prop_definition = ChildResponsiveComponent.arguments[:responsive_prop]
    assert_instance_of(Primer::Responsive::ArgumentDefinition, responsive_prop_definition)
    assert_instance_of(Primer::Responsive::ResponsiveVariantArgumentDefinition, responsive_prop_definition.responsive_variants[:v_narrow])
    assert_instance_of(Primer::Responsive::ResponsiveVariantArgumentDefinition, responsive_prop_definition.responsive_variants[:v_regular])
    assert_equal(1, responsive_prop_definition.default_value(:v_narrow))
    assert_equal(2, responsive_prop_definition.default_value(:v_regular))

    # teardown
    Object.send(:remove_const, :ChildResponsiveComponent)
  end

  def test_add_arguments_definition_class_method_inherits_parent_props
    # arrange
    parent_klass = Class.new(Primer::Alpha::ResponsiveComponent) do
      arguments_definition(
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
      add_arguments_definition(
        parent_prop_a: prop(
          type: String,
          default: "overwriting argument definition"
        ),
        child_prop: prop(
          responsive: :yes,
          type: Integer
        )
      )
    end
    Object.send(:const_set, :ChildResponsiveComponent, child_klass)

    # assert
    parent_prop_a = ChildResponsiveComponent.arguments[:parent_prop_a]
    original_prop_a = ParentResponsiveComponent.arguments[:parent_prop_a]

    parent_prop_b = ChildResponsiveComponent.arguments[:parent_prop_b]
    original_prop_b = ParentResponsiveComponent.arguments[:parent_prop_b]

    child_prop = ChildResponsiveComponent.arguments[:child_prop]

    assert_instance_of(Primer::Responsive::ArgumentDefinition, parent_prop_a)
    assert_instance_of(Primer::Responsive::ArgumentDefinition, parent_prop_b)
    assert_instance_of(Primer::Responsive::ArgumentDefinition, child_prop)

    refute_equal(original_prop_a, parent_prop_a, "Child arguments with same name should overwrite parent's argument definition")
    assert_equal(original_prop_b, parent_prop_b, "Parent's arguments should be inherited unless overwritten by Child arguments_definition")

    # teardown
    Object.send(:remove_const, :ParentResponsiveComponent)
    Object.send(:remove_const, :ChildResponsiveComponent)
  end
end
