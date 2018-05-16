# frozen_string_literal: false

require 'carrot-top'
require 'inifile'

module Sensu
  module Plugin
    module RabbitMQ
      module Options
        def add_common_options
          option :host,
                 description: 'RabbitMQ management API host',
                 long: '--host HOST',
                 default: 'localhost'

          option :port,
                 description: 'RabbitMQ management API port',
                 long: '--port PORT',
                 proc: proc(&:to_i),
                 default: 15_672

          option :vhost,
                 description: 'Regular expression for filtering the RabbitMQ vhost',
                 short: '-v',
                 long: '--vhost VHOST',
                 default: ''

          option :username,
                 description: 'RabbitMQ management API user',
                 long: '--username USER',
                 default: 'guest'

          option :password,
                 description: 'RabbitMQ management API password',
                 long: '--password PASSWORD',
                 default: 'guest'

          option :ssl,
                 description: 'Enable SSL for connection to the API',
                 long: '--ssl',
                 boolean: true,
                 default: false

          option :ini,
                 description: 'Configuration ini file',
                 short: '-i',
                 long: '--ini VALUE'
        end
      end

      module Common
        def acquire_rabbitmq_info(property = nil)
          begin
            if config[:ini]
              ini = IniFile.load(config[:ini])
              section = ini['auth']
              username = section['username']
              password = section['password']
            else
              username = config[:username]
              password = config[:password]
            end

            rabbitmq_info = CarrotTop.new(
              host: config[:host],
              port: config[:port],
              user: username,
              password: password,
              ssl: config[:ssl]
            )
          rescue StandardError
            warning 'could not get rabbitmq info'
          end

          result_info = rabbitmq_info
          unless property.nil?
            result_info = rabbitmq_info.send property
            if config[:vhost] != ''
              result_info.select! { |x| x['vhost'].match(config[:vhost]) }
            end
          end

          result_info
        end

        def queue_list_builder(input)
          return [] if input.nil?
          return [input] if config[:regex]
          input.split(',')
        end

        def self.included(receiver)
          receiver.extend(Sensu::Plugin::RabbitMQ::Options)
          receiver.add_common_options
        end
      end
    end
  end
end
