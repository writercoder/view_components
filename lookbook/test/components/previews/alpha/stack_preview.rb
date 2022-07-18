# frozen_string_literal: true

module Alpha
  # @label Stack
  class StackPreview < ViewComponent::Preview
    # @label Playground
    #
    # @param backdrop select [visible, transparent, none]
    # @param motion select [auto, none]
    # @param open [Boolean] toggle
    # @param width select [auto, xsmall, small, medium, large, xlarge, xxlarge]
    # @param height select [auto, xsmall, small, medium, large, xlarge]
    def playground(backdrop: nil, motion: nil, placement: nil, open: false, width: nil, height: nil)
      render_with_template(
        # locals: {
        #   backdrop: backdrop&.to_sym,
        #   motion: motion&.to_sym,
        #   placement: placement&.to_sym,
        #   open: open,
        #   width: width&.to_sym,
        #   height: height&.to_sym
        # },
        template: "alpha/stack_preview"
      )
    end
  end
end
