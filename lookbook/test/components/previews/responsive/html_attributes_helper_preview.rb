# frozen_string_literal: true

module Responsive
  # @label HtmlAttributesHelper
  class HtmlAttributesHelperPreview < ViewComponent::Preview
    extend Primer::Responsive::HtmlAttributesHelper

    MAIN_TEMPLATE = "responsive/responsive_preview_output"

    # @label Sanitization
    def sanitization
      attributes = {
        "data-status": "open",
        onclick: "javascript: jsCallback()",
        slot: "custom-title",
        custom_attr: "some random value",
        class: "custom-style-class another-style-class this-style-class",
        id: "unique-item-01",
        for: "unique-input-2"
      }
      additional_allowed_attributes = [:for]

      sanitized = self.class.sanitize_html_attributes(attributes, additional_allowed_attributes: additional_allowed_attributes)

      panels = [
        {
          title: "additional allowed attributes",
          output: additional_allowed_attributes.pretty_inspect
        }, {
          title: "raw attributes",
          output: attributes.pretty_inspect
        }, {
          title: "sanitized",
          output: sanitized.pretty_inspect
        }
      ]

      render_with_template(
        locals: { panels: panels },
        template: MAIN_TEMPLATE
      )
    end
  end
end
