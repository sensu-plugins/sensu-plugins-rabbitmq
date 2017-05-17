#!/usr/bin/env ruby
#  encoding: UTF-8
#
# RabbitMQ Queue Metrics
# ===
#
# DESCRIPTION:
# This plugin checks gathers by default the following per queue rabbitmq metrics:
#   - message count
#   - average egress rate
#   - "drain time" metric, which is the time a queue will take to reach 0 based on the egress rate
#   - consumer count
# The list of gathered metrics can also be specified with an option
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
# Copyright 2011 Sonian, Inc <chefs@sonian.net>
# Copyright 2015 Tim Smith <tim@cozy.co> and Cozy Services Ltd.
# Copyright 2017 Romain Thouvenin <romain@thouvenin.pro>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/metric/cli'
require 'socket'
require 'carrot-top'
require 'inifile'

# main plugin class
class RabbitMQMetrics < Sensu::Plugin::Metric::CLI::Graphite
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
         description: 'Metric naming scheme, text to prepend to $queue_name.$metric',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.rabbitmq"

  option :filter,
         description: 'Regular expression for filtering queues',
         long: '--filter REGEX'

  option :metrics,
         description: 'Regular expression for filtering metrics in each queue',
         long: '--metrics REGEX',
         default: '^messages$|consumers|drain_time|avg_egress'

  option :ssl,
         description: 'Enable SSL for connection to the API',
         long: '--ssl',
         boolean: true,
         default: false

  option :ini,
         description: 'Configuration ini file',
         short: '-i',
         long: '--ini VALUE'

  def acquire_rabbitmq_queues
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
      warning 'could not get rabbitmq queue info'
    end

    if config[:vhost]
      return rabbitmq_info.queues.select { |x| x['vhost'].match(config[:vhost]) }
    end

    rabbitmq_info.queues
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
    acquire_rabbitmq_queues.each do |queue|
      if config[:filter]
        next unless queue['name'].match(config[:filter])
      end

      # calculate and output time till the queue is drained in drain metrics
      queue['messages'] ||= 0
      drain_time = queue['messages'] / queue['backing_queue_status']['avg_egress_rate']
      drain_time = 0 if drain_time.nan? || drain_time.infinite? # 0 rate with 0 messages is 0 time to drain
      queue['drain_time'] = drain_time.to_i

      metrics = dotted_keys(queue)
      metrics.each do |metric|
        next unless metric.match(config[:metrics])
        value = queue.dig(*metric.split('.'))
        # Special case of ingress and egress rates for backward-compatibility
        if metric =~ /backing_queue_status.avg/
          value = format('%.4f', value)
          metric = metric.split('.')[-1]
        end
        output("#{config[:scheme]}.#{queue['name']}.#{metric}", value, timestamp) unless value.nil?
      end
    end

    ok
  end
end
