# frozen_string_literal: true

module Primer
  module Alpha
    # Placehold doc for Stack component
    class Stack < Primer::Component
      extend Primer::StyleClassMapHelper
      include Primer::PropertySpaceHelper

      status :alpha

      attr_accessor :properties

      renders_many :items

      STYLE_CLASS_MAP = {
        default: "Stack"
      }.merge add_responsive_variants(
        {
          direction: {
            inline: "Stack--dir-inline",
            block: "Stack--dir-block"
          }.freeze,
          gap: {
            none: "Stack--gap-none",
            condensed: "Stack--gap-condensed",
            normal: "Stack--gap-normal",
            spacious: "Stack--gap-spacious"
          }.freeze,
          align: {
            stretch: "Stack--align-stretch",
            start: "Stack--align-start",
            center: "Stack--align-center",
            end: "Stack--align-end",
            baseline: "Stack--align-baseline"
          }.freeze,
          spread: {
            start: "Stack--spread-start",
            center: "Stack--spread-center",
            end: "Stack--spread-end",
            distribute: "Stack--spread-distribute",
            distributeEvenly: "Stack--spread-distributeEvenly"
          }.freeze,
          wrap: {
            wrap: "Stack--wrap",
            nowrap: "Stack--nowrap"
          }.freeze,
          align_wrap: {
            start: "Stack--alignWrap-start",
            center: "Stack--alignWrap-center",
            end: "Stack--alignWrap-end",
            distribute: "Stack--alignWrap-distribute",
            distributeEvenly: "Stack--alignWrap-distributeEvenly"
          }.freeze,
          show_dividers: "Stack--showDividers"
        }
      ).freeze

      PROPERTY_SPACE = {
        direction: {
          values: [:inline, :block].freeze,
          responsive: :optional,
          default: :block
        }.freeze,
        gap: {
          values: [:none, :condensed, :normal, :spacious].freeze,
          responsive: :optional,
          default: :normal
        }.freeze,
        align: {
          values: [:stretch, :start, :center, :end, :baseline].freeze,
          responsive: :optional,
          default: :stretch
        }.freeze,
        align_wrap: {
          values: [:start, :center, :end, :distribute, :distributeEvenly].freeze,
          responsive: :optional,
          default: :start
        }.freeze,
        spread: {
          values: [:start, :center, :end, :distribute, :distributeEvenly].freeze,
          responsive: :optional,
          default: :start
        }.freeze,
        wrap: {
          values: [:wrap, :nowrap].freeze,
          responsive: :optional,
          default: :nowrap
        }.freeze,
        show_dividers: {
          values: [true, false].freeze,
          responsive: :optional,
          default: false
        },
        divider_aria_role: {
          values: [:presentation, :separator, :none],
          responsive: :optional,
          when_narrow: { default: :none },
          default: :presentation
        }
      }.freeze

      def initialize(**properties)
        @properties = fill_defaults property_space: PROPERTY_SPACE, properties: properties
      end

      def divider_aria_role
        @properties[:divider_aria_role]
      end

      def show_divider?
        true
      end

      def default_style_class_map
        STYLE_CLASS_MAP
      end

      def applied_style_classes
        self.class.apply_style_map(STYLE_CLASS_MAP, @properties)
      end

      def stack_classes
        classes = [STYLE_CLASS_MAP[:default]]

        applied_style_classes.each_value do |value|
          classes.push(value)
        end

        classes.join(" ")
      end
    end

    # placeholder stack item
    class StackItem < Primer::Component
      extend Primer::StyleClassMapHelper
      status :alpha

      PROPERTY_SPACE = {
        expand: {
          values: [true, false].freeze,
          responsive: true,
          DEFAULT: false
        }.freeze,
        keep_size: {
          values: [true, false].freeze,
          responsive: true,
          DEFAULT: false
        }.freeze
      }.freeze
    end
  end
end
