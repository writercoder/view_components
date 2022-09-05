# frozen_string_literal: true

module Experiments
  module SampleComponents
    # @label Default slot config
    class ChildWithSlotsComponent < WithSlotsComponent
      status :alpha

      @default_icon = :log
    end
  end
end
