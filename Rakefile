# frozen_string_literal: true

$stdout.sync = true

require "rake/testtask"
require "yaml"
require "pathname"

task default: :test

namespace :test do
  desc "Run all tests"

  Rake::TestTask.new(:accessibility) do |t|
    t.warning = false
    t.libs << "test"
    t.test_files = FileList["test/accessibility_test.rb"]
  end
end

task :test do
  if ENV["TEST"]
    Rake::Task["test:single"].invoke
  else
    Rake::Task["test:all"].invoke
  end
end
