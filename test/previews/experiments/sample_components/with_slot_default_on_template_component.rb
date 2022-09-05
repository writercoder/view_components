# frozen_string_literal: true

module Experiments
  module SampleComponents
    # @label Default slot config
    class WithSlotDefaultOnTemplateComponent < Primer::Component
      status :alpha

      renders_one :private_leading_action, types: {
        icon: Primer::OcticonComponent,
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
