require 'sensu-plugin/check/cli'
require 'sensu-plugin/metric/cli'
require 'socket'

require 'sensu-plugins-rabbitmq/version'

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

      def self.included(receiver)
        receiver.extend(Sensu::Plugin::RabbitMQ::Options)
        receiver.add_common_options
      end
    end
  end
end

class RabbitMQCheck < Sensu::Plugin::Check::CLI
  include Sensu::Plugin::RabbitMQ

  def acquire_rabbitmq_info
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
    rescue
      warning 'could not get rabbitmq info'
    end
    rabbitmq_info
  end

  # To avoid complaints from mother class at the end of tests (at_exit handler)
  def run
    ok
  end
end

class RabbitMQMetrics < Sensu::Plugin::Metric::CLI::Graphite
  include Sensu::Plugin::RabbitMQ

  option :scheme,
         description: 'Metric naming scheme',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.rabbitmq"

  def acquire_rabbitmq_info(property)
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
    rescue
      warning 'could not get rabbitmq info'
    end

    result_info = rabbitmq_info.send property
    if config[:vhost]
      return result_info.select { |x| x['vhost'].match(config[:vhost]) }
    end

    result_info
  end

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
