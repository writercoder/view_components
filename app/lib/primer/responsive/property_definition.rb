# frozen_string_literal: true

module Primer
  module Responsive
    # Property definition helps defining, validating, and deprecating the property of responsive components
    class PropertyDefinition
      ALLOWED_PARAMS = [
        :name,
        :variant_name,
        :allowed_values,
        :type,
        :default,
        :deprecation,
        :responsive
      ].concat(PropertiesDefinitionHelper::RESPONSIVE_VARIANTS).freeze
      RESPONSIVE_OPTIONS = [:no, :transitional, :yes].freeze

      attr_accessor :name
      attr_reader(
        :allowed_values,
        :type,
        :default,
        :deprecation,
        :responsive,
        :responsive_variants
      )

      def initialize(params = {})
        @params = params
        validate_params_structure unless PropertiesDefinitionHelper.production_env?

        @name = params[:name]
        @allowed_values = params[:allowed_values]
        @type = params[:type]
        @default = params[:default]
        @deprecation = create_deprecation(params)
        @responsive = params.fetch(:responsive, :no)

        @are_variants_required = false
        unless @responsive == :no
          @responsive_variants = {}
          PropertiesDefinitionHelper::RESPONSIVE_VARIANTS.each do |variant|
            next unless params.key? variant

            @responsive_variants[variant] = ResponsiveVariantPropertyDefinition.new(
              name: @name,
              variant_name: variant,
              **params[variant]
            )
            @are_variants_required ||= @responsive_variants[variant].required?
          end
        end

        @has_defined_default = params.key?(:default)

        validate_definition unless PropertiesDefinitionHelper.production_env?
      end

      # tells if the property is required by checking if it or its reponsive variants have defaults
      def required?
        !@has_defined_default && (responsive?(:no) || @are_variants_required)
      end

      # checks responsive type of responsiveness in general
      def responsive?(responsive_type = nil)
        return @responsive == responsive_type unless responsive_type.nil?

        @responsive != :no
      end

      def defined_default?(variant = nil)
        return @has_defined_default if variant.nil?
        return @responsive_variants[variant].defined_default? if @responsive_variants.key?(variant)

        false
      end

      def default_value(variant = nil)
        return @default unless responsive?
        return @default if variant.nil? || !defined_default?(variant)

        defined_default?(variant) ? @responsive_variants[variant].default : @default
      end

      def valid_value?(value, variant = nil)
        # deprecated values are considered valid, even though they're discouraged
        return true if deprecated_value?(value)

        # type can't be changed based on responsive variants
        return value.is_a?(@type) unless @type.nil?

        if @responsive == :no
          return @allowed_values.include?(value) unless @allowed_values.nil?

          # if no allowed_values and no type is specified, the value is always valid
          return true
        end

        return true if @allowed_values.include?(value)
        return false if variant.nil?

        responsive_variant = @responsive_variants[variant]

        # definition with no type and no allowed_values allows anything
        return true if @allowed_values.nil? && (responsive_variant.nil? || responsive_variant.allowed_values.nil?)

        !!responsive_variant&.allowed_values&.include?(value)
      end

      def validate_value(value, variant = nil)
        return if valid_value?(value, variant)

        base_message = invalid_value_base_message(value)

        unless @type.nil?
          raise PropertiesDefinitionHelper::InvalidPropertyValueError, <<~MSG
            #{base_message}
            Value has to be of type #{@type.inspect}.
          MSG
        end

        allowed_values = @allowed_values || []
        responsive_variant = @responsive_variants[variant] unless @responsive_variants.nil?

        if responsive_variant
          variant_allowed_values = responsive_variant&.allowed_values || []
          all_allowed_values = allowed_values.concat(variant_allowed_values)

          raise PropertiesDefinitionHelper::InvalidPropertyValueError, <<~MSG
            #{base_message}
            Value for responsive variant "#{variant.inspect}" has to be one of #{all_allowed_values.inspect}.
          MSG
        end

        raise PropertiesDefinitionHelper::InvalidPropertyValueError, <<~MSG
          #{base_message}
          Value has to be one of #{allowed_values.inspect}.
        MSG
      end

      def deprecated?
        !@deprecation.nil? && @deprecation.property_deprecated?
      end

      def deprecated_value?(value)
        return false if @deprecation.nil?

        @deprecation.deprecated_value?(value)
      end

      def deprecation_warn_message(value)
        return "" if @deprecation.nil?

        @deprecation.deprecation_warn_message(value)
      end

      def invalid_value_base_message(value)
        "Invalid value for \"#{@name.inspect}\": provided \"#{value.inspect}\"(#{value.class.inspect})."
      end

      private

      def error_base_message
        "Invalid property definition for \"#{@name.inspect}\"."
      end

      def validate_params_structure(params = nil)
        params = @params if params.nil?

        params.each_key do |key|
          next if ALLOWED_PARAMS.include? key

          raise PropertiesDefinitionHelper::InvalidPropertyDefinitionError, <<~MSG
            Invalid property definition param:
            Param `#{key.inspect}` is not a valid definition parameters.
            Allowed parameters: `#{ALLOWED_PARAMS.inspect}`
          MSG
        end
      end

      # Validates the property definition when developing a responsive component.
      # Triggers automatically on instantiation when not in production
      def validate_definition
        if !@allowed_values.nil? && !@type.nil?
          raise PropertiesDefinitionHelper::InvalidPropertyDefinitionError, <<~MSG
            #{error_base_message}
            Definition cannot contain both :type and :allowed_values.
          MSG
        end

        unless valid_responsive_option?
          raise PropertiesDefinitionHelper::InvalidPropertyDefinitionError, <<~MSG
            #{error_base_message}
            Invalid :responsive value: #{responsive.inspect}. Allowed values for :responsive are: #{RESPONSIVE_OPTIONS.inspect}.
          MSG
        end

        if responsive? :no
          PropertiesDefinitionHelper::RESPONSIVE_VARIANTS.each do |variant|
            next unless @params.key? variant

            raise PropertiesDefinitionHelper::InvalidPropertyDefinitionError, <<~MSG
              #{error_base_message}
              Properties not responsive can't have responsive variants definition, but #{variant.inspect} found.
              To fix this, change :responsive to :transitional or :yes
            MSG
          end
        else
          if @type.nil?
            # responsive definition cannot contain :allowed_values already part or the main definition of @allowed_values
            @responsive_variants.each do |variant_name, responsive_variant|
              next if responsive_variant.allowed_values.nil?

              repeated_values = @allowed_values & responsive_variant.allowed_values
              next if repeated_values.empty?

              raise PropertiesDefinitionHelper::InvalidPropertyDefinitionError, <<~MSG
                #{error_base_message}
                Responsive variant can't have @allowed_values existent in @allowed_values of the property definition.
                To fix, remove #{repeated_values.inspect} from #{variant_name.inspect} responsive variant.
              MSG
            end
          elsif @responsive_variants.values.any? { |rv| !rv.allowed_values.nil? }
            # responsive definition cannot contain :allowed_values if the main definition is @type
            raise PropertiesDefinitionHelper::InvalidPropertyDefinitionError, <<~MSG
              #{error_base_message}
              Responsive variant can't use @allowed_values when main definition is @type based.
            MSG
          end

          responsive_variants_with_default = []
          @responsive_variants.each_value do |responsive_variant|
            responsive_variant.validate_definition
            next unless responsive_variant.defined_default?

            responsive_variants_with_default << responsive_variant.variant_name
            if responsive?(:yes) && defined_default?
              raise PropertiesDefinitionHelper::InvalidPropertyDefinitionError, <<~MSG
                #{error_base_message}
                A responsive-only type (responsive: :yes) cannot contain a variant :default at the same
                time it defines an overall :default. Remove the base :default, or remove all variants :default
              MSG
            end

            if @type.nil?
              validate_default_value_by_allowed_values(
                (@allowed_values || []) + (responsive_variant.allowed_values || []),
                responsive_variant.default
              )
            else
              validate_default_value_by_type(responsive_variant.default)
            end
          end

          unless responsive_variants_with_default.empty?
            PropertiesDefinitionHelper::RESPONSIVE_VARIANTS_MAP.each do |key, config|
              next if config[:optional]
              next if responsive_variants_with_default.include? key

              raise PropertiesDefinitionHelper::InvalidPropertyDefinitionError, <<~MSG
                #{error_base_message}
                If a responsive property defines a default in at least one responsive variant,
                all required responsive variants have to also define a default value.
                Variant with default: #{responsive_variants_with_default.inspect}
                Variant missing default: #{PropertiesDefinitionHelper::REQUIRED_RESPONSIVE_VARIANTS - responsive_variants_with_default}
              MSG
            end
          end
        end

        unless @deprecation.nil?
          if !@deprecation.type.nil? && @deprecation.type == @type
            raise PropertiesDefinitionHelper::InvalidPropertyDefinitionError, <<~MSG
              #{error_base_message}
              Deprecated type can't be the same as property type
            MSG
          end

          unless @deprecation.deprecated_values.nil?
            current_allowed_values = (@allowed_values || []) + (@responsive_variants&.values&.map(&:allowed_values)&.flatten || [])
            repeated_attrs = current_allowed_values & @deprecation.deprecated_values
            unless repeated_attrs.empty?
              raise PropertiesDefinitionHelper::InvalidPropertyDefinitionError, <<~MSG
                #{error_base_message}
                Deprecated values #{@deprecation.deprecated_values.inspect} can't be part of the allowed_values of the property: #{repeated_attrs.inspect}
              MSG
            end
          end
        end

        return unless defined_default?

        if @type.nil?
          validate_default_value_by_allowed_values(@allowed_values, @default)
        else
          validate_default_value_by_type(@default)
        end
      end

      def validate_default_value_by_allowed_values(allowed_values, value)
        return if allowed_values.nil? || allowed_values.any?(value)

        raise PropertiesDefinitionHelper::InvalidPropertyDefinitionError, <<~MSG
          #{error_base_message}
          Default value #{value.inspect}(#{value.class.inspect}) has to be one of #{allowed_values.inspect}.
        MSG
      end

      def validate_default_value_by_type(value)
        return if value.is_a? @type

        raise PropertiesDefinitionHelper::InvalidPropertyDefinitionError, <<~MSG
          #{error_base_message}
          Default value #{value.inspect}(#{value.class.inspect}) has to be of type #{@type.inspect}.
        MSG
      end

      def valid_responsive_option?
        RESPONSIVE_OPTIONS.include? @responsive
      end

      def create_deprecation(params)
        return nil unless params.key? :deprecation

        deprecation_params = {
          property_definition: self,
          **params[:deprecation]
        }
        PropertyDeprecation.new(**deprecation_params)
      end
    end

    # Internal class only to be used as part of a responsive property definition
    class ResponsiveVariantPropertyDefinition < PropertyDefinition
      DENY_RESPONSIVE_VARIANT_ATTRIBUTES = [:type, :responsive, :deprecation].freeze

      attr_reader :variant_name

      def initialize(params = {})
        @variant_name = params[:variant_name]
        super(params)
      end

      def validate_definition
        invalid_attrs = [*PropertiesDefinitionHelper::RESPONSIVE_VARIANTS, *DENY_RESPONSIVE_VARIANT_ATTRIBUTES] & @params.keys
        return if invalid_attrs.empty?

        raise PropertiesDefinitionHelper::InvalidPropertyDefinitionError, <<~MSG
          #{error_base_message}
          Responsive variants cannot have the following attributes as part of their definitions: #{DENY_RESPONSIVE_VARIANT_ATTRIBUTES.inspect}
          Invalid attributes found for #{@variant_name.inspect}: #{invalid_attrs.inspect}
        MSG
      end
    end

    # Handles deprecation of properties or values as part of the responsive property definition
    class PropertyDeprecation
      # @property: deprecates the whole property. Defaults to true if @deprecated_values and @type are not set
      # @deprecated_values: array of deprecated values that cannot be used moving forward
      # @type: if a type was changed into another and the old type is still supported. This should be the old supported type
      # @warn_message: explanations for the deprecation on top of what is presented by default
      attr_reader :deprecated_values, :type, :warn_message

      def initialize(property_definition: nil, property: false, deprecated_values: nil, type: nil, warn_message: "")
        @property_definition = property_definition
        @deprecated_values = deprecated_values
        @type = type

        @property = deprecated_values.nil? && type.nil? ? true : property

        @warn_message = warn_message
      end

      def deprecation_warn(value_given = nil)
        return unless PropertiesDefinitionHelper.production_env? || silent_deprecation?

        deprecation_message = deprecation_warn_message(value_given)
        ActiveSupport::Deprecation.warn(deprecation_message)
      end

      def deprecation_warn_message(value_given = nil)
        return "" unless deprecated_value? value_given

        property_name = @property_definition.name.inspect
        msg = if @property
                "Property #{property_name} is deprecated."
              elsif !@type.nil?
                "Type #{@type.inspect} is deprecated for property #{property_name}. Use type #{@property_definition.type.inspect} instead. Value provided: #{value_given.inspect}(#{value_given.class.inspect})"
              else
                "#{@deprecated_values.inspect} #{@deprecated_values.length > 1 ? 'are' : 'is'} deprecated for property #{property_name}. Value provided: #{value_given.inspect}"
              end
        msg = "DEPRECATION: #{msg}"
        msg += "\n             #{@warn_message}" unless @warn_message.empty?

        msg
      end

      def property_deprecated?
        @property
      end

      def deprecated_value?(value)
        # property deprecation means that all values are deprecated
        return true if @property

        @type.nil? ? @deprecated_values.any?(value) : value.is_a?(@type)
      end

      def silent_deprecation?
        Rails.application.config.primer_view_components.silence_deprecations
      end
    end
  end
end
