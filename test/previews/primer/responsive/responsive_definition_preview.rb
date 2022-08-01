# frozen_string_literal: true

module Primer
  module Responsive
    # @label PropertyDefinition
    class ResponsiveDefinitionPreview < ViewComponent::Preview
      MAIN_TEMPLATE = "primer/responsive/responsive_preview_output"
      ERROR_STYLE = "color: darkred"

      # @label Property validation playground
      #
      # @param show_object toggle
      # @param responsive select [~, [_no, no], transitional, yes]
      # @param allowed_values text
      # @param allowed_values_type select [~, String, Integer]
      # @param type select [~, String, Integer]
      # @param default text
      # @param default_type select [~, String, Integer]
      # @param when_narrow_allowed_values text
      # @param when_narrow_allowed_values_type select [~, String, Integer]
      # @param when_narrow_default text
      # @param when_narrow_default_type select [~, String, Integer]
      # @param when_regular_allowed_values text
      # @param when_regular_allowed_values_type select [~, String, Integer]
      # @param when_regular_default text
      # @param when_regular_default_type select [~, String, Integer]
      def definition_validation_playground(
        show_object: false,
        responsive: "",
        allowed_values: "",
        allowed_values_type: "",
        default: "",
        default_type: "",
        type: "",
        when_narrow_allowed_values: "",
        when_narrow_allowed_values_type: "",
        when_narrow_default: "",
        when_narrow_default_type: "",
        when_regular_allowed_values: "",
        when_regular_allowed_values_type: "",
        when_regular_default: "",
        when_regular_default_type: ""
      )
        props = { name: :component_property }
        responsive = :no if responsive == "false"
        props[:responsive] = responsive.to_sym unless responsive.empty?

        unless allowed_values.empty?
          props[:allowed_values] = allowed_values.split(",").map(&:strip)
          props[:allowed_values] = props[:allowed_values].map(&:to_i) if allowed_values_type == "Integer"
        end

        unless default.empty?
          default = default.to_i if default_type == "Integer"
          props[:default] = default
        end

        unless type.empty?
          props[:type] = case type
                         when "String"
                           String
                         when "Integer"
                           Integer
                         end
        end

        unless when_narrow_allowed_values.empty? && when_narrow_default.empty?
          props[:when_narrow] = {}
          when_narrow = props[:when_narrow]
          unless when_narrow_allowed_values.empty?
            when_narrow[:allowed_values] = when_narrow_allowed_values.split(",").map(&:strip)
            when_narrow[:allowed_values] = when_narrow[:allowed_values].map(&:to_i) if when_narrow_allowed_values_type == "Integer"
          end
          unless when_narrow_default.empty?
            when_narrow_default = when_narrow_default.to_i if when_narrow_default_type == "Integer"
            when_narrow[:default] = when_narrow_default
          end
        end

        unless when_regular_allowed_values.empty? && when_regular_default.empty?
          props[:when_regular] = {}
          when_regular = props[:when_regular]
          unless when_regular_allowed_values.empty?
            when_regular[:allowed_values] = when_regular_allowed_values.split(",").map(&:strip)
            when_regular[:allowed_values] = when_regular[:allowed_values].map(&:to_i) if when_regular_allowed_values_type == "Integer"
          end
          unless when_regular_default.empty?
            when_regular_default = when_regular_default.to_i if when_regular_default_type == "Integer"
            when_regular[:default] = when_regular_default
          end
        end

        begin
          property_definition = Primer::Responsive::PropertyDefinition.new(props)
        rescue Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError => e
          error_message = e.message
        end

        panels = []
        panels << { title: "props", output: props.pretty_inspect }
        panels << { title: "object", output: property_definition.pretty_inspect } if show_object
        panels << { title: "ERROR", style: ERROR_STYLE, output: error_message } if error_message.present?

        render_with_template(
          locals: { panels: panels },
          template: MAIN_TEMPLATE
        )
      end

      # @label Validate value
      #
      # @param value text
      # @param value_type select [String, Symbol]
      # @param responsive_variant select [~, when_narrow, when_regular, when_wide]
      def validate_value(value: "", value_type: "String", responsive_variant: "")
        props = {
          name: :test,
          allowed_values: [:a, :b, :c],
          responsive: :transitional,
          default: :a,
          when_narrow: {
            allowed_values: [:d, :e],
            default: :d
          },
          when_regular: {
            default: :b
          },
          when_wide: {
            allowed_values: [:xl]
          },
          deprecation: {
            deprecated_values: [:x, :g]
          }
        }

        property_definition = Primer::Responsive::PropertyDefinition.new(props)

        responsive_variant = responsive_variant.empty? ? nil : responsive_variant.to_sym
        case value_type
        when "Integer"
          value = value.empty? ? 0 : value.to_i
        when "Symbol"
          value = value.empty? ? nil : value.to_sym
        end

        log_message = "valid?: #{property_definition.valid_value?(value, responsive_variant).inspect}, "
        log_message += "deprecated? #{property_definition.value_deprecated?(value)}"

        begin
          property_definition.validate_value(value, responsive_variant)
        rescue Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyValueError => e
          error_message = e.message
        end

        panels = []
        panels << { title: "props", output: props.pretty_inspect }
        panels << { title: "value", output: value.pretty_inspect }
        panels << { title: "log", output: log_message }

        panels << { title: "error", style: ERROR_STYLE, output: error_message } if error_message.present?

        render_with_template(
          locals: { panels: panels },
          template: MAIN_TEMPLATE
        )
      end

      # @label Valid definition
      #
      # @param show_object toggle
      def stress_test(show_object: false)
        props = {
          name: :test,
          allowed_values: [:a, :b, :c],
          responsive: :transitional,
          default: :a,
          when_narrow: {
            allowed_values: [:d, :e],
            default: :d
          },
          when_regular: {
            default: :b
          },
          when_wide: {
            allowed_values: [:xl]
          },
          deprecation: {
            deprecated_values: [:x]
          }
        }

        begin
          property_definition = Primer::Responsive::PropertyDefinition.new(props)
        rescue Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError => e
          error_message = e.message
        end

        panels = []
        panels << { title: "props", output: props.pretty_inspect }
        panels << { title: "object", output: property_definition.pretty_inspect } if show_object
        panels << { title: "ERROR", style: ERROR_STYLE, output: error_message } if error_message.present?

        render_with_template(
          locals: { panels: panels },
          template: MAIN_TEMPLATE
        )
      end

      # @label Error: invalid default
      #
      # @param show_object toggle
      def invalid_default_type(show_object: false)
        props = {
          name: :test,
          type: Numeric,
          default: "Hello"
        }

        begin
          property_definition = Primer::Responsive::PropertyDefinition.new(props)
        rescue Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError => e
          error_message = e.message
        end

        # output
        panels = []
        panels << { title: "props", output: props.pretty_inspect }
        panels << { title: "object", output: property_definition.pretty_inspect } if show_object
        panels << { title: "ERROR", style: ERROR_STYLE, output: error_message }

        render_with_template(
          locals: { panels: panels },
          template: MAIN_TEMPLATE
        )
      end

      # @label Errors: invalid responsive default
      #
      # @param show_object toggle
      def invalid_default(show_object: false)
        props = {
          name: :test,
          allowed_values: [1, 2, 3],
          responsive: :yes,
          when_narrow: {
            allowed_values: [4, 5],
            default: 6
          }
        }

        begin
          property_definition = Primer::Responsive::PropertyDefinition.new(props)
        rescue Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError => e
          error_message = e.message
        end

        # output
        panels = []
        panels << { title: "props", output: props.pretty_inspect }
        panels << { title: "object", output: property_definition.pretty_inspect } if show_object
        panels << { title: "ERROR", style: ERROR_STYLE, output: error_message }

        render_with_template(
          locals: { panels: panels },
          template: MAIN_TEMPLATE
        )
      end

      # @label Errors: :type × :allowed_values
      #
      # @param show_object toggle
      def definition_error_type_values(show_object: false)
        props = {
          name: :test,
          type: String,
          responsive: :transitional,
          when_narrow: {
            allowed_values: [1, 2],
            default: 1
          }
        }

        begin
          property_definition = Primer::Responsive::PropertyDefinition.new(props)
        rescue Primer::Responsive::PropertiesDefinitionHelper::InvalidPropertyDefinitionError => e
          error_message = e.message
        end

        # output
        panels = []
        panels << { title: "props", output: props.pretty_inspect }
        panels << { title: "object", output: property_definition.pretty_inspect } if show_object
        panels << { title: "ERROR", style: ERROR_STYLE, output: error_message }

        render_with_template(
          locals: { panels: panels },
          template: MAIN_TEMPLATE
        )
      end

      # @!group Deprecation
      # @label Deprecation: value
      def deprecate_value
        props = {
          name: :test,
          allowed_values: [1, 2, 3, 4],
          responsive: :yes,
          deprecation: {
            deprecated_values: [5, 6],
            warn_message: "Support for these values is going to be dropped in the next release"
          }
        }
        property_definition = Primer::Responsive::PropertyDefinition.new(props)
        error_message = property_definition.deprecation_warn_message(5)

        # output
        panels = []
        panels << { title: "props", output: props.pretty_inspect }
        panels << { style: ERROR_STYLE, output: error_message }

        render_with_template(
          locals: { panels: panels },
          template: MAIN_TEMPLATE
        )
      end

      # @label Deprecation: type
      def deprecate_type
        props = {
          name: :test,
          type: String,
          deprecation: {
            type: Integer
          }
        }
        property_definition = Primer::Responsive::PropertyDefinition.new(props)
        error_message = property_definition.deprecation_warn_message(5)

        # output
        panels = []
        panels << { title: "props", output: props.pretty_inspect }
        panels << { style: ERROR_STYLE, output: error_message }

        render_with_template(
          locals: { panels: panels },
          template: MAIN_TEMPLATE
        )
      end

      # @label Deprecation: property
      def deprecate_property
        props = {
          name: :test,
          allowed_values: [1, 2, 3],
          deprecation: {
            warn_message: "This property is unsafe and will be sunset in version 1.8"
          }
        }
        property_definition = Primer::Responsive::PropertyDefinition.new(props)

        error_message = property_definition.deprecation_warn_message(5)

        # output
        panels = []
        panels << { title: "props", output: props.pretty_inspect }
        panels << { style: ERROR_STYLE, output: error_message }

        render_with_template(
          locals: { panels: panels },
          template: MAIN_TEMPLATE
        )
      end
      # @!endgroup
    end
  end
end
