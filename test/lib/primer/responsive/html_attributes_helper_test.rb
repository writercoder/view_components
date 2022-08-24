# frozen_string_literal: true

require "test_helper"

class ArgumentsDefinitionHelperTest < Minitest::Test
  include Primer::Responsive::HtmlAttributesHelper

  def test_validate_html_attributes_raises_error_if_not_allowed_attribute_is_present
    attributes = {
      id: ""
    }
  end

  def test_sanitize_html_attributes_removes_not_allowed_attributes
    
  end
end
