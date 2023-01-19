# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "minitest/autorun"
require "rails"

require File.expand_path("../demo/config/environment.rb", __dir__)
