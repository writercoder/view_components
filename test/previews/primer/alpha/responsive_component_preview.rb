# frozen_string_literal: true

module Primer
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
      def property_values_defaults(
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

        cloned_values = values.deep_dup
        component = Alpha::DummyResponsiveComponent.new(property_values: cloned_values)
        cloned_values = component.fill_default_values(cloned_values)

        panels = [
          { title: "Values", output: cloned_values.pretty_inspect },
          { title: "Component", output: component.pretty_inspect }
        ]

        render_with_template(
          locals: { panels: panels },
          template: "primer/responsive/responsive_preview_output"
        )
      end

      # @label Fill with default values
      def definition_validation_fill_defaults
        values = {
          uuid: "unique-hash",
          id: "test",
          spacing: :not_defined,
          placement: {
            container: :middle
          }
        }

        cloned_values = values.deep_dup
        component = Alpha::DummyResponsiveComponent.new(property_values: cloned_values)
        with_default_values = component.fill_default_values(cloned_values, fallback_to_default: false)

        panels = [
          { title: "Values", output: values.pretty_inspect },
          { title: "Values with default", output: with_default_values.pretty_inspect },
          { title: "Component", output: component.pretty_inspect }
        ]

        render_with_template(
          locals: { panels: panels },
          template: "primer/responsive/responsive_preview_output"
        )
      end

      # @!group Html Attributes
      # @label html attributes validation
      def invalid_html_attributes
        html_attributes = {
          class: %w[class-a class-b class-c],
          autofocus: true,
          type: "datetime"
        }

        begin
          ChildDummyResponsiveComponent.new(
            property_values: {},
            html_attributes: html_attributes
          )
        rescue Primer::Responsive::HtmlAttributesHelper::InvalidHtmlAttributeError => e
          error_message = "#{e.message}*In production, html attributes are going to be sanitized, but no exception is thrown."
        end

        panels = [
          { title: "Attributes", output: html_attributes.pretty_inspect },
          { title: "Error", output: error_message }
        ]

        render_with_template(
          locals: { panels: panels },
          template: "primer/responsive/responsive_preview_output"
        )
      end

      # @label Rendering html attributes
      def html_attributes_render
        component = ChildDummyResponsiveComponent.new(
          property_values: {},
          html_attributes: {
            class: %w[class-a class-b class-c],
            data: {
              "entity-id": 1234,
              readonly: :readonly,
              disabled: true,
              "entity-title": "Clean-up taks list"
            },
            autofocus: true
          }
        )

        render_with_template(
          locals: { component: component, ViewComponent: ViewComponent },
          template: "primer/alpha/responsive_component_attribute_render"
        )
      end

      # @!endgroup

      # @label property definitions
      def property_definitions
        begin
          component = DummyResponsiveComponent.new
        rescue => e
          error_message = e.message
        end
        render_with_template(
          locals: {
            props: nil, #Alpha::DummyResponsiveComponent::PROPS_DEFINITION_FOR_TESTS.pretty_inspect,
            component: component.pretty_inspect,
            error_message: error_message
          },
          template: "primer/alpha/responsive_component_preview"
        )
      end

      # @label property definitions inheritance
      def inherited_property_definitions
        component = ChildDummyResponsiveComponent.new(
          html_attributes: {
            id: "unique-id",
            for: "some-id",
            autocomplete: "autocomplete"
          }
        )

        render_with_template(
          locals: {
            props: nil,
            component: component.pretty_inspect,
            error_message: nil
          },
          template: "primer/alpha/responsive_component_preview"
        )
      end
    end

    # === COMPONENT CLASS TESTS ===
    # class for testing responsive component class methods
    class DummyResponsiveComponent < Primer::Alpha::ResponsiveComponent
      properties_definition(
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
          responsive: :exclusive,
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
              responsive: :exclusive,
              when_wide: {
                default: :test_c
              }
            )
          }
        }
      )

      def initialize(property_values: {}, html_attributes: {})
        super
        @props = DummyResponsiveComponent.properties
      end

      def should_raise_error?
        true
      end
    end

    # dummy class to test inherited properties
    class ChildDummyResponsiveComponent < DummyResponsiveComponent
      add_allowed_html_attributes :for, :autocomplete

      add_properties_definition(
        id: prop(
          type: String,
          default: "10"
        ),
        name: prop(
          type: String,
          responsive: :exclusive,
          default: "no name"
        )
      )

      style_class_map(
        general: {
          id: {
            "0": "ChildComponent-not-persisted"
          }
        },
        responsive: {
          name: {
            "no mame": "ChildComponent-nameless"
          },
          spacing: {
            s: "ChildComponent-spacing-Small",
            m: "ChildComponent-spacing-Medium",
            l: "ChildComponent-spacing-Large",
          }
        },
        with_responsive: {
          placement: {
            viewport: {
              center: "ChildComponent-Viewport-Center",
              top: "ChildComponent-Viewport-Top",
              bottom: "ChildComponent-Viewport-Bottom",
              full: "ChildComponent-Viewport-Full",
            }
          }
        }
      )

      def initialize(property_values: {}, html_attributes: {})
        super
        @props = ChildDummyResponsiveComponent.properties
      end
    end

    # class for responsive default tests
    class DefaultValuesResponsiveComponent < Primer::Alpha::ResponsiveComponentPreview
      properties_definition(
        responsive_a: prop(
          allowed_values: [:a, :b, :c],
          default: :b,
          responsive: :exclusive
        ),
        responsive_opt_a: prop(
          allowed_values: [:a, :b, :c],
          default: :b,
          responsive: :optional
        ),
        responsive_b: prop(
          allowed_values: [:a, :b, :c],
          default: :b,
          responsive: :exclusive,
          when_narrow: { default: :a },
          when_wide: { default: :c }
        ),
        nested: {
          responsive_c: prop(
            allowed_values: [:a, :b],
            responsive: :exclusive,
            when_narrow: {
              allowed_values: [:na, :nb],
              default: :na
            },
            when_regular: {
              allowed_values: [:rd, :re],
              default: :a
            },
            when_wide: {
              allowed_values: [:wc, :wd],
              default: :wd
            }
          )
        }
      )
    end
  end
end
