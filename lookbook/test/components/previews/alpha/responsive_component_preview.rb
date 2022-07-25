# frozen_string_literal: true

module Alpha
  # @label ResponsiveComponent
  class ResponsiveComponentPreview < ViewComponent::Preview
    # @label Values validation playground
    #
    # @param uuid text
    # @param id number
    # @param spacing select [~, xs, s, m, l, xl, xxl]
    # @param spacing_when_narrow select [~, xs, s, m, l, xl, xxl]
    # @param spacing_when_regular select [~, xs, s, m, l, xl, xxl]
    # @param spacing_when_wide select [~, xs, s, m, l, xl, xxl]
    # @param placement_viewport select [~, center, top, bottom, full]
    # @param placement_viewport_when_narrow select [~, center, top, bottom, full]
    # @param placement_viewport_when_regular select [~, center, top, bottom, full]
    # @param placement_viewport_when_wide select [~, center, top, bottom, full]
    # @param placement_container select [~, top, right, bottom, left]
    def definition_validation_playground(
      uuid: "",
      id: 0,
      spacing: nil,
      spacing_when_narrow: nil,
      spacing_when_regular: nil,
      spacing_when_wide: nil,
      placement_viewport: nil,
      placement_viewport_when_narrow: nil,
      placement_viewport_when_regular: nil,
      placement_viewport_when_wide: nil,
      placement_container: nil
    )
      values = {}
      values[:uuid] = uuid unless uuid.empty?
      values[:id] = id unless id.zero?
      values[:spacing] = spacing.to_sym unless spacing.nil?
      values[:spacing_when_narrow] = spacing_when_narrow.to_sym unless spacing_when_narrow.nil?
      values[:spacing_when_regular] = spacing_when_regular.to_sym unless spacing_when_regular.nil?
      values[:spacing_when_wide] = spacing_when_wide.to_sym unless spacing_when_wide.nil?
      values[:placement_viewport] = placement_viewport.to_sym unless placement_viewport.nil?
      values[:placement_viewport_when_narrow] = placement_viewport_when_narrow.to_sym unless placement_viewport_when_narrow.nil?
      values[:placement_viewport_when_regular] = placement_viewport_when_regular.to_sym unless placement_viewport_when_regular.nil?
      values[:placement_viewport_when_wide] = placement_viewport_when_wide.to_sym unless placement_viewport_when_wide.nil?
      values[:placement_container] = placement_container.to_sym unless placement_container.nil?

      cloned_values = values.clone
      component = Alpha::DummyResponsiveComponent.new(cloned_values)
      cloned_values = component.fill_default_values(cloned_values)

      panels = [
        { title: "Values", output: cloned_values.pretty_inspect },
        { title: "Component", output: component.pretty_inspect }
      ]

      render_with_template(
        locals: { panels: panels },
        template: "responsive/responsive_preview_output"
      )
    end

    # @label property definitions
    def property_definitions
      begin
        component = Alpha::DummyResponsiveComponent.new
      rescue => e
        error_message = e.message
      end
      render_with_template(
        locals: {
          props: nil, #Alpha::DummyResponsiveComponent::PROPS_DEFINITION_FOR_TESTS.pretty_inspect,
          component: component.pretty_inspect,
          error_message: error_message
        },
        template: "alpha/responsive_component_preview"
      )
    end

    # @label property definitions inheritance
    def inherited_property_definitions
      begin
        component = Alpha::ChildDummyResponsiveComponent.new(
          property_values: {},
          html_attributes: {
            id: "unique-id",
            for: "some-id",
            autocomplete: "autocomplete",
            onclick: "javascript: callback()"
          }
      )
      rescue => e
        error_message = e.message
      end

      component.sanitize_html_attributes!
      render_with_template(
        locals: {
          props: nil,
          component: component.pretty_inspect,
          error_message: error_message
        },
        template: "alpha/responsive_component_preview"
      )
    end
  end

  # === COMPONENT CLASS TESTS ===
  # class for testing responsive component class methods
  class DummyResponsiveComponent < Primer::Alpha::ResponsiveComponent
    PROPS_DEFINITION_FOR_TESTS = {
      uuid: prop(
        type: String
      ),
      id: prop(
        type: Integer,
        default: 0
      ),
      spacing: prop(
        allowed_values: [:s, :m, :l],
        default: :m,
        responsive: :optional,
        when_narrow: {
          default: :s
        },
        when_regular: {
          allowed_values: [:xs, :xl],
          default: :l
        },
        when_wide: {
          allowed_values: [:xl, :xxl],
          default: :xl
        }
      ),
      placement: {
        viewport: prop(
          allowed_values: [:center, :top, :bottom, :full],
          default: :center,
          responsive: :optional,
          when_narrow: { default: :full }
        ),
        container: prop(
          allowed_values: [:top, :right, :bottom, :left],
          default: :bottom
        )
      },
      double: {
        namespace: {
          test_prop: prop(
            allowed_values: [:test_a, :test_b, :test_c],
            default: :test_a,
            responsive: :optional,
            when_wide: {
              default: :test_c
            }
          )
        }
      }
    }.freeze

    properties_definition(PROPS_DEFINITION_FOR_TESTS)

    def initialize(property_values: {}, html_attributes: {})
      super
      @props = DummyResponsiveComponent.properties
    end
  end

  # dummy class to test inherited properties
  class ChildDummyResponsiveComponent < DummyResponsiveComponent
    add_allowed_html_attributes :for, :autocomplete

    properties_definition(
      id: prop(
        type: String,
        default: "10"
      ),
      name: prop(
        type: String,
        responsive: :optional,
        default: "no name"
      )
    )

    def initialize(property_values: {}, html_attributes: {})
      super
      @props = ChildDummyResponsiveComponent.properties
    end
  end
end
