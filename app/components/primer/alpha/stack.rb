# frozen_string_literal: true

require "json"

module Primer
  module Alpha
    # Placehold doc for Stack component
    class Stack < Primer::Component
      extend Primer::StyleMapHelper

      status :alpha

      renders_many :items

      STYLE_MAPPING = add_responsive_variants(
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
            stretch: "Stack--align",
            start: "Stack--align-start",
            center: "Stack--align-center",
            end: "Stack--align-end",
            baseline: "Stack--align-baseline"
          }.freeze,
          spread: {
            start: "Stack--spread-start",
            center: "Stack--spread-center",
            end: "Stack--spread-end",
            distribute: "Stack--spread-baseline",
            distributeEvenly: "Stack--spread-baseline"
          }.freeze,
          wrap: {
            wrap: "Stack--wrap",
            nowrap: "Stack--nowrap"
          }.freeze,
          alignWrap: {
            start: "Stack--alignWrap-start",
            center: "Stack--alignWrap-center",
            end: "Stack--alignWrap-end",
            distribute: "Stack--alignWrap-distribute",
            distributeEvenly: "Stack--alignWrap-distributeEvenly"
          }.freeze
        }
      ).freeze

      PROPERTY_SPACE = {
        direction: {
          values: [:inline, :block].freeze,
          responsive: true,
          DEFAULT: :block
        }.freeze,
        gap: {
          values: [:none, :condensed, :normal, :spacious].freeze,
          responsive: true,
          DEFAULT: :normal
        }.freeze,
        align: {
          values: [:stretch, :start, :center, :end, :baseline].freeze,
          responsive: true,
          DEFAULT: :stretch
        }.freeze,
        alignWrap: {
          values: [:start, :center, :end, :distribute, :distributeEvenly].freeze,
          responsive: true,
          DEFAULT: :start
        }.freeze,
        spread: {
          values: [:start, :center, :end, :distribute, :distributeEvenly].freeze,
          responsive: true,
          DEFAULT: :start
        }.freeze,
        wrap: {
          values: [:wrap, :nowrap].freeze,
          responsive: true,
          DEFAULT: :nowrap
        }.freeze,
        showDivider: {
          values: [true, false].freeze,
          responsive: true,
          narrow: {
            values: [:inherit],
            DEFAULT: :inherit
          },
          DEFAULT: false
        },
        dividerAriaRole: {
          values: [:presentation, :separator, :none],
          responsive: true,
          narrow: { DEFAULT: :none },
          DEFAULT: :presentation
        }
      }.freeze

      def initialize
        @x = 10
      end

      def styles_map
        STYLE_MAPPING.to_json
      end
    end
  end
end
