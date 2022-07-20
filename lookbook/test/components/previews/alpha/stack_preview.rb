# frozen_string_literal: true

module Alpha
  # @label Stack
  class StackPreview < ViewComponent::Preview

    # @label Responsive
    def responsive
      render_with_template(
        locals: {
          props: {
            divider_aria_role: :presentation,
            show_dividers: true,
            when_narrow: {
              direction: :inline,
              gap: :spacious,
              align: :stretch,
              spread: :center
            },
            when_regular: {
              direction: :block,
              gap: :normal,
              align: :start,
              spread: :start
            }
          }
        },
        template: "alpha/stack_preview"
      )
    end

    # @label Playground
    #
    # @param direction select [inline, block]
    # @param gap select [none, condensed, normal, spacious]
    # @param align select [stretch, start, center, end, baseline]
    # @param align_wrap select [start, center, end, distribute, distributeEvenly]
    # @param spread select [start, center, end, distribute, distributeEvenly]
    # @param wrap select [wrap, nowrap]
    # @param show_dividers [Boolean] toggle
    # @param divider_aria_role select [presentation, separator, none]
    def playground(
      direction: nil,
      gap: nil,
      align: nil,
      align_wrap: nil,
      spread: nil,
      wrap: nil,
      show_dividers: false,
      divider_aria_role: nil
    )
      render_with_template(
        locals: {
          props: {
            direction: direction.nil? ? nil : direction.to_sym,
            gap: gap.nil? ? nil : gap.to_sym,
            align: align.nil? ? nil : align.to_sym,
            align_wrap: align_wrap.nil? ? nil : align_wrap.to_sym,
            spread: spread.nil? ? nil : spread.to_sym,
            wrap: wrap.nil? ? nil : wrap.to_sym,
            show_dividers: show_dividers.nil? ? false : show_dividers,
            divider_aria_role: divider_aria_role.nil? ? nil : divider_aria_role.to_sym
          }
        },
        template: "alpha/stack_preview"
      )
    end
  end
end
