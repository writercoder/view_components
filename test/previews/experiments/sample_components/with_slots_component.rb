# frozen_string_literal: true

module Experiments
  module SampleComponents
    # @label Default slot config
    class WithSlotsComponent < Primer::Component
      status :alpha

      @default_icon = :alert

      class << self
        attr_reader :default_icon
      end

      renders_one :private_leading_action, types: {
        icon: lambda { |**system_arguments|
          system_arguments[:icon] = self.class.default_icon unless system_arguments.key? :icon
          Primer::OcticonComponent.new(**system_arguments)
        },
        svg: lambda { |**system_arguments|
          Primer::BaseComponent.new(tag: :svg, **system_arguments)
        }
      }

      def initialize(**system_arguments)
        @system_arguments = deny_tag_argument(**system_arguments)
        @system_arguments[:tag] = :div
      end
    end
  end
end
