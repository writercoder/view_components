# frozen_string_literal: true

module Primer
  module Alpha
    # Base class for Responsive Components
    class ResponsiveComponent < Primer::Component
      extend Primer::Responsive::HtmlAttributesHelper
      extend Primer::Responsive::PropertiesDefinitionHelper
      extend Primer::Responsive::StyleClassMapHelper

      attr_reader :property_values, :html_attributes

      # class instance variables
      @additional_allowed_html_attributes = nil
      @properties = nil
      @style_map = nil

      # Declares a list of allowed HTML attributes to be used when validating/sanitizing the attributes
      def self.add_allowed_html_attributes(*additional_allowed_html_attributes)
        additional_allowed_html_attributes.flatten! if additional_allowed_html_attributes.is_a? Array
        @additional_allowed_html_attributes = additional_allowed_html_attributes
      end

      # Defines all properties part of the component props API
      def self.properties_definition(all_properties_definition)
        @properties = properties_definition_builder(all_properties_definition)
      end

      # Adds property definitions to the componennt props API
      # To be used in child components that want to reuse its parent's property definitions
      # - if a propery with the same name is added, it'll overwrite the parent's property definition
      # NOTE: favor composition over inheritance when creating components whenever possible.
      #       This method is supposed to be used with "abstract" or "base" parent component classes
      def self.add_properties_definition(new_properties_definition)
        new_properties = properties_definition_builder(new_properties_definition)
        @properties = !superclass.respond_to?(:properties) || superclass.properties.nil? ? new_properties : { **superclass.properties, **new_properties }
      end

      # Declares the class map of a component
      # @param general [Hash] map without responsive support
      # @param responsive [Hash] replaces the map with its responsive variants
      # @param with_responsive [Hash] adds responsive variants to the map while keeping it's original structure
      def self.style_class_map(general: {}, responsive: {}, with_responsive: {})
        @style_map = {
          **general,
          **add_responsive_variants(responsive, remove_initial: true),
          **add_responsive_variants(with_responsive)
        }.freeze
      end

      def initialize(property_values: {}, html_attributes: {})
        @property_values = property_values
        @html_attributes = html_attributes

        # validate_html_attributes unless Primer::Responsive::PropertiesDefinitionHelper.production_env?
        # sanitize_html_attributes!
      end

      def validate_html_attributes(html_attributes = nil)
        html_attributes = @html_attributes if html_attributes.nil?
        self.class.validate_html_attributes(html_attributes, self.class.additional_allowed_html_attributes)
      end

      # Sanitizes @html_attributes or a custom html_attributes, if provided
      def sanitize_html_attributes(html_attributes = nil)
        html_attributes = @html_attributes if use_instance_variable
        self.class.sanitize_html_attributes(html_attributes, self.class.additional_allowed_attributes)
      end

      # Sanitizes and updates @html_attributes
      def sanitize_html_attributes!
        @html_attributes = self.class.sanitize_html_attributes(
          @html_attributes,
          additional_allowed_attributes: self.class.additional_allowed_html_attributes
        )
      end

      def fill_default_values(property_values = {})
        self.class.fill_missing_values_with_default(
          properties_definition: self.class.properties,
          property_values: property_values
        )
      end

      def fill_default_values!
        @property_values = fill_default_values(@property_values)
      end

      def validate_values(property_values = nil)
        property_values = @property_values if property_values.nil?
        self.class.validate_property_values(property_values)
      end

      def style_class_map
        self.class.style_map
      end

      def filtered_style_class_map
        @filtered_map unless @filtered_map.nil?

        @filtered_map = filter_style_class_map(@property_values)
      end

      def filter_style_class_map(property_values = nil)
        {} if self.class.style_map.nil?

        property_values = @property_values if property_values.nil?
        self.class.apply_values_to_style_map(self.class.style_map, property_values)
      end

      class << self
        attr_accessor :properties, :style_map, :additional_allowed_html_attributes
      end
    end
  end
end
