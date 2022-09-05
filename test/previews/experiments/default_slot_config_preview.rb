# frozen_string_literal: true

module Experiments
  # @label Default slot config
  class DefaultSlotConfigPreview < ViewComponent::Preview
    # @!group default in code
    # @label including the default slot
    def default
      render(SampleComponents::WithSlotsComponent.new) do |wsc|
        wsc.private_leading_action_icon
      end
    end

    # @label skipping the slot entirely
    def empty
      render(SampleComponents::WithSlotsComponent.new)
    end

    # @label slot with custom icon
    def with_custom
      render(SampleComponents::WithSlotsComponent.new) do |wsc|
        wsc.private_leading_action_icon(icon: :table)
      end
    end

    # @label slot with svg instead
    def svg
      render(SampleComponents::WithSlotsComponent.new) do |wsc|
        wsc.private_leading_action_svg
      end
    end

    def child_with_different_default_icon
      render(SampleComponents::ChildWithSlotsComponent.new, &:private_leading_action_icon)
    end
    # @!endgroup

    # @!group default in template
    # @label icon override
    def template_icon_default
      render(SampleComponents::WithSlotDefaultOnTemplateComponent.new)
    end
    # @!endgroup
  end
end
