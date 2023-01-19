# frozen_string_literal: true

require "system/test_case"

class AccessibilityTest < System::TestCase
  def test_google
    visit("https://www.hawksley.org:80")
    assert_accessible
  end
end
