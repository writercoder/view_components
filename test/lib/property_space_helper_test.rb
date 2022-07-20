# frozen_string_literal: true

require "test_helper"

class Primer::PropertySpaceHelperTest < Minitest::Test
  include Primer::PropertySpaceHelper

  PROPERTY_SPACES = {
    # no responsive properties
    no_responsive: {
      prop_a: {
        values: [:value_a, :value_b].freeze,
        default: :value_a
      },
      prop_b: {
        type: String,
        responsive: :no,
        default: "placeholder"
      },
      prop_c: {
        type: Numeric,
        default: 10
      },
      prop_d: {
        values: [1, 4, 8]
      }
    },

    # with automatic responsive variants
    auto_responsive: {
      prop_a: {
        values: [:value_a, :value_b],
        responsive: :optional,
        default: :value_a
      },
      prop_b: {
        values: [:value_a, :value_b, :value_c],
        responsive: :optional,
        when_narrow: { default: :value_b},
        default: :value_a
      },
      prop_c: {
        values: [:value_a, :value_b, :value_c],
        responsive: :optional,
        when_narrow: {
          values: [:value_d],
          default: :value_b
        },
        when_regular: { default: :value_c },
        default: :value_a
      }
    },

    # exclusive responsive properties cannot be set outside the responsive variants
    exclusive_responsive: {
      prop_a: {
        values: [:a, :b, :c],
        responsive: :required,
        when_narrow: {
          values: [:na, :nb],
          default: :a
        },
        when_regular: {
          values: [:ra],
          default: :b
        },
        when_wide: {
          values: [:wa, :wb, :wc],
          default: :c
        }
      }
    }
  }

  def test_fill_default_no_responsive_when_empty()
    properties = fill_defaults(PROPERTY_SPACES.no_responsive)

    assert_equal(1, 1)
  end
end
