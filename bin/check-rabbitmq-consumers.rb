#!/usr/bin/env ruby
# frozen_string_literal: true

# Check RabbitMQ consumers
# ===
#
# DESCRIPTION:
# This plugin checks the number of consumers on the RabbitMQ server
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
# Copyright 2014 Daniel Kerwin <d.kerwin@gini.net>
# Copyright 2014 Tim Smith <tim@cozy.co>
# Copyright 2018 Mike Murray <37150283+monkey670@users.noreply.github.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugins-rabbitmq'
require 'sensu-plugins-rabbitmq/check'

# main plugin class
class CheckRabbitMQConsumers < Sensu::Plugin::RabbitMQ::Check
  option :regex,
         description: 'Treat the --queue flag as a regular expression.',
         long: '--regex',
         boolean: true,
         default: false

  option :queue,
         description: 'Comma separated list of RabbitMQ queues to monitor.',
         long: '--queue queue_name'

  option :exclude,
         description: 'Comma separated list of RabbitMQ queues to NOT monitor.  All others will be monitored.',
         long: '--exclude queue_name'

  option :warn,
         short: '-w NUM_CONSUMERS',
         long: '--warn NUM_CONSUMERS',
         proc: proc(&:to_i),
         description: 'WARNING consumer count threshold',
         default: 5

  option :critical,
         short: '-c NUM_CONSUMERS',
         long: '--critical NUM_CONSUMERS',
         description: 'CRITICAL consumer count threshold',
         proc: proc(&:to_i),
         default: 2

  def return_condition(missing, critical, warning)
    if critical.count > 0 || missing.count > 0
      message = []
      message << "Queues in critical state: #{critical.join(', ')}. " if critical.count > 0
      message << "Queues missing: #{missing.join(', ')}" if missing.count > 0
      critical(message.join("\n"))
    elsif warning.count > 0
      warning("Queues in warning state: #{warning.join(', ')}")
    else
      ok
    end
  end

  def run
    queue_list = queue_list_builder(config[:queue])
    exclude_list = queue_list_builder(config[:exclude])
    # create arrays to hold failures
    missing = if config[:regex]
                []
              else
                queue_list || []
              end
    critical = []
    warn = []
    rabbitmq = acquire_rabbitmq_info
    begin
      rabbitmq.queues.each do |queue|
        # if specific queues were passed only monitor those.
        # if specific queues to exclude were passed then skip those
        if config[:regex]
          if config[:queue] && config[:exclude]
            next unless queue['name'] =~ /#{queue_list.first}/ && queue['name'] !~ /#{exclude_list.first}/
          else
            next unless queue['name'] =~ /#{queue_list.first}/
          end
        elsif config[:queue]
          next unless queue_list.include?(queue['name'])
        elsif config[:exclude]
          next if exclude_list.include?(queue['name'])
        end
        missing.delete(queue['name'])
        consumers = queue['consumers'] || 0
        critical.push("#{queue['name']}:#{queue['consumers']}-Consumers") if consumers <= config[:critical]
        warn.push("#{queue['name']}:#{queue['consumers']}-Consumers") if consumers <= config[:warn]
      end
    rescue StandardError
      critical 'Could not find any queue, check rabbitmq server'
    end
    return_condition(missing, critical, warn)
  end
end
