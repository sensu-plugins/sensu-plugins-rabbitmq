# frozen_string_literal: false

require 'sensu-plugin/check/cli'
require 'sensu-plugins-rabbitmq/rabbitmq'

module Sensu
  module Plugin
    module RabbitMQ
      class Check < Sensu::Plugin::Check::CLI
        include Sensu::Plugin::RabbitMQ::Common

        # To avoid complaints from mother class at the end of tests (at_exit handler)
        def run
          ok
        end
      end
    end
  end
end
