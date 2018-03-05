# frozen_string_literal: true

require 'sensu-plugin/metric/cli'
require 'socket'
require 'sensu-plugins-rabbitmq/rabbitmq'

module Sensu
  module Plugin
    module RabbitMQ
      class Metrics < Sensu::Plugin::Metric::CLI::Graphite
        include Sensu::Plugin::RabbitMQ::Common

        option :scheme,
               description: 'Metric naming scheme',
               long: '--scheme SCHEME',
               default: "#{Socket.gethostname}.rabbitmq"

        def dotted_keys(hash, prefix = '', keys = [])
          hash.each do |k, v|
            if v.is_a? Hash
              keys = dotted_keys(v, prefix + k + '.', keys)
            else
              keys << prefix + k
            end
          end
          keys
        end

        # To avoid complaints from mother class at the end of tests (at_exit handler)
        def run
          ok
        end
      end
    end
  end
end
