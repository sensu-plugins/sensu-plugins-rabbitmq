#!/usr/bin/env ruby
#  encoding: UTF-8
#
# RabbitMQ Exchange Metrics
# ===
#
# DESCRIPTION:
# This plugin gathers by default all the available exchange metrics.
# The list of gathered metrics can also be specified with an option
#
# Code mostly copied from metrics-rabbitmq-queue
#
# PLATFORMS:
#   Linux, BSD, Solaris
#
# DEPENDENCIES:
#   RabbitMQ rabbitmq_management plugin
#   gem: sensu-plugin
#   gem: carrot-top
#
# LICENSE:
# Copyright 2017 Romain Thouvenin <romain@thouvenin.pro>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/metric/cli'
require 'socket'
require 'carrot-top'
require 'inifile'

# main plugin class
class RabbitMQExchangeMetrics < Sensu::Plugin::Metric::CLI::Graphite
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
         long: '--vhost VHOST'

  option :username,
         description: 'RabbitMQ management API user',
         long: '--username USER',
         default: 'guest'

  option :password,
         description: 'RabbitMQ management API password',
         long: '--password PASSWORD',
         default: 'guest'

  option :scheme,
         description: 'Metric naming scheme, text to prepend to $exchange_name.$metric',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.rabbitmq"

  option :filter,
         description: 'Regular expression for filtering exchanges',
         long: '--filter REGEX'

  option :metrics,
         description: 'Regular expression for filtering metrics in each exchange',
         long: '--metrics REGEX'

  option :ssl,
         description: 'Enable SSL for connection to the API',
         long: '--ssl',
         boolean: true,
         default: false

  option :ini,
         description: 'Configuration ini file',
         short: '-i',
         long: '--ini VALUE'

  def acquire_rabbitmq_exchanges
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
      warning 'could not get rabbitmq exchange info'
    end

    if config[:vhost]
      return rabbitmq_info.exchanges.select { |x| x['vhost'].match(config[:vhost]) }
    end

    rabbitmq_info.exchanges
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

  def run
    timestamp = Time.now.to_i
    acquire_rabbitmq_exchanges.each do |exchange|
      if config[:filter]
        next unless exchange['name'].match(config[:filter])
      end

      metrics = dotted_keys(exchange)
      metrics.each do |metric|
        if config[:metrics]
          next unless metric.match(config[:metrics])
        end
        value = exchange.dig(*metric.split('.'))
        output("#{config[:scheme]}.#{exchange['name']}.#{metric}", value, timestamp) unless value.nil?
      end
    end

    ok
  end
end
