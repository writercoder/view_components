# frozen_string_literal: true

require "test_helper"

class PropertyDefinitionTest < Minitest::Test
  def test_params_validation_raises_if_not_allowed_params_found
    # arrange
    not_allowed_param = :inexistent_param
    params = {
      type: String,
      default: "Valid default"
    }
    params[not_allowed_param] = "irrelevant value"

    # act / assert
    error = assert_raises(Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError) do
      Primer::Responsive::PropertyDefinition.new(params)
    end
    assert(error.message.include?(not_allowed_param.to_s))
  end

  def test_valid_definition_cannot_containt_type_and_allowed_values_simultaneously
    # arrange
    params = {
      type: String,
      allowed_values: %w[value_a value_b]
    }

    # act / assert
    assert_raises(Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError) do
      Primer::Responsive::PropertyDefinition.new(params)
    end
  end

  def test_valid_definition_with_type_and_default_has_default_value_of_the_same_type
    # arrange
    params = {
      type: String,
      default: 10
    }

    # act / assert
    assert_raises(Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError) do
      Primer::Responsive::PropertyDefinition.new(params)
    end
  end

  def test_valid_definition_with_type_and_variant_default_has_default_value_of_the_same_type
    # arrange
    params = {
      type: String,
      responsive: :yes,
      when_narrow: { default: 1 },
      when_regular: { default: 2 }
    }

    # act / assert
    assert_raises(Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError) do
      Primer::Responsive::PropertyDefinition.new(params)
    end
  end

  def test_valid_definition_responsive_type_has_to_be_valid
    # arrange
    params = {
      responsive: :inexistent_responsive_option
    }

    # act / assert
    error = assert_raises(Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError) do
      Primer::Responsive::PropertyDefinition.new(params)
    end
    assert(error.message.include?("responsive"))
  end

  def test_valid_definition_not_responsive_definition_cant_have_reponsive_variants
    # arrange
    params = {
      allowed_values: [:a, :b],
      responsive: :no,
      when_narrow: { default: :a }
    }

    # act / assert
    error = assert_raises(Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError) do
      Primer::Responsive::PropertyDefinition.new(params)
    end
    assert(error.message.include?("responsive"))
  end

  def test_valid_definition_responsive_variants_cant_have_allowed_values_duplicates
    # arrange
    params = {
      allowed_values: [:duplicate_value, :value_a, :value_b],
      responsive: :yes,
      when_narrow: {
        allowed_values: [:duplicate_value, :narrow_a]
      }
    }

    # act / assert
    assert_raises(Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError) do
      Primer::Responsive::PropertyDefinition.new(params)
    end
  end

  def test_valid_definition_responsive_variants_cant_have_type_defined
    params = {
      type: String,
      responsive: :yes,
      when_narrow: { type: String }
    }

    error = assert_raises(Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError) do
      Primer::Responsive::PropertyDefinition.new(params)
    end

    assert(error.message.include?("type"))
  end

  def test_valid_definition_fully_responsive_property_cant_have_variant_default_and_overall_default_simultaneously
    params = {
      type: String,
      default: "overall_default",
      responsive: :yes,
      when_narrow: { default: "narrow_default" }
    }

    error = assert_raises(Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError) do
      Primer::Responsive::PropertyDefinition.new(params)
    end

    assert(error.message.include?("default"))
  end

  def test_valid_definition_responsive_variants_require_all_default_to_be_explicit_if_at_least_one_defines_it
    params = {
      type: String,
      responsive: :yes,
      when_narrow: { default: "narrow" }
    }

    error = assert_raises(Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError) do
      Primer::Responsive::PropertyDefinition.new(params)
    end

    assert(error.message.include?("default"))
  end
end
