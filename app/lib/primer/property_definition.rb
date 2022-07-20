# frozen_string_literal: true

module Primer
  # property space helper
  class PropertyDefinition
    attr_accessor(
      :values,
      :type,
      :responsive,
      :narrow,
      :regular,
      :wide,
      :default
    )

    def initialize(values: nil, type: nil, responsive: false, narrow: nil, regular: nil, wide: nil, default: nil)
      
    end
  end
end
