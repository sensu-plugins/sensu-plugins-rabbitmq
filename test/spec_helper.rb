# frozen_string_literal: true

require 'codeclimate-test-reporter'
require 'simplecov'
require 'simplecov-console'

RSpec.configure do |c|
  # Sensu plugins run in the context of an at_exit handler. This prevents
  # code-under-test from being run at the end of the rspec suite.
  c.before(:each) do
    Sensu::Plugin::CLI.class_eval do
      # PluginStub
      class PluginStub
        def run; end

        def ok(*); end

        def warning(*); end

        def critical(*); end

        def unknown(*); end
      end
      class_variable_set(:@@autorun, PluginStub)
    end
  end
end

CodeClimate::TestReporter.start

def timestamp
  kind_of Numeric
end

SimpleCov.minimum_coverage 80
SimpleCov.refuse_coverage_drop
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ]
)
SimpleCov.start do
  add_filter '/test/'
end
