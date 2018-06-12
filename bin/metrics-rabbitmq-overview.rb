#!/usr/bin/env ruby
# frozen_string_literal: true

#
# RabbitMQ Overview Metrics
# ===
#
# DESCRIPTION:
# RabbitMQ 'overview' stats are similar to what is shown on the main page
# of the rabbitmq_management web UI. Example:
#
#   $ rabbitmq-queue-metrics.rb
#    host.rabbitmq.queue_totals.messages.count 0 1344186404
#    host.rabbitmq.queue_totals.messages.rate  0.0 1344186404
#    host.rabbitmq.queue_totals.messages_unacknowledged.count  0 1344186404
#    host.rabbitmq.queue_totals.messages_unacknowledged.rate 0.0 1344186404
#    host.rabbitmq.queue_totals.messages_ready.count 0 1344186404
#    host.rabbitmq.queue_totals.messages_ready.rate  0.0 1344186404
#    host.rabbitmq.message_stats.publish.count 4605755 1344186404
#    host.rabbitmq.message_stats.publish.rate  17.4130186829638  1344186404
#    host.rabbitmq.message_stats.deliver_no_ack.count  6661111 1344186404
#    host.rabbitmq.message_stats.deliver_no_ack.rate 24.6867565643405  1344186404
#    host.rabbitmq.message_stats.deliver_get.count 6661111 1344186404
#    host.rabbitmq.message_stats.deliver_get.rate  24.6867565643405  1344186404
#    host.rabbitmq.object_totals.channels.count 138 1344186404
#    host.rabbitmq.object_totals.connections.count 88 1344186404
#    host.rabbitmq.object_totals.consumers.count 127 1344186404
#    host.rabbitmq.object_totals.exchanges.count 184 1344186404
#    host.rabbitmq.object_totals.queues.count 90 1344186404
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
# Copyright 2012 Joe Miller - https://github.com/joemiller
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

  option :ssl,
         description: 'Enable SSL for connection to the API',
         long: '--ssl',
         boolean: true,
         default: false

  option :ini,
         description: 'Configuration ini file',
         short: '-i',
         long: '--ini VALUE'

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
    rescue StandardError
      warning 'could not get rabbitmq info'
    end
    rabbitmq_info
  end

  def run #rubocop:disable all
    timestamp = Time.now.to_i

    rabbitmq = acquire_rabbitmq_info
    overview = rabbitmq.overview

    # overview['queue_totals']['messages']
    if overview.key?('queue_totals') && !overview['queue_totals'].empty?
      %w[messages messages_ready messages_unacknowledged].each do |key|
        output "#{config[:scheme]}.queue_totals.#{key}.count", overview['queue_totals'][key], timestamp
        output "#{config[:scheme]}.queue_totals.#{key}.rate", overview['queue_totals']["#{key}_details"]['rate'], timestamp
      end
    end

    if overview.key?('message_stats') && !overview['message_stats'].empty?
      %w[deliver_get deliver_no_ack publish].each do |key|
        # overview['message_stats']['publish']
        if overview['message_stats'].include?(key)
          output "#{config[:scheme]}.message_stats.#{key}.count", overview['message_stats'][key], timestamp
        end
        if overview['message_stats'].include?("#{key}_details") &&
           overview['message_stats']["#{key}_details"].include?('rate')
          output "#{config[:scheme]}.message_stats.#{key}.rate", overview['message_stats']["#{key}_details"]['rate'], timestamp
        end
      end
    end

    if overview.key?('object_totals') && !overview['object_totals'].empty?
      %w[channels connections consumers exchanges queues].each do |key|
        if overview['object_totals'].include?(key)
          output "#{config[:scheme]}.object_totals.#{key}.count", overview['object_totals'][key], timestamp
        end
      end
    end

    ok
  end
end
