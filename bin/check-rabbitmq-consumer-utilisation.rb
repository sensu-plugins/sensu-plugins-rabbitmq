#!/usr/bin/env ruby
# frozen_string_literal: true

# Check RabbitMQ consumer utilisation
# ===
#
# DESCRIPTION:
# This plugin checks the consumer utilisation percentage.
# The fraction of time in which the queue is able to immediately deliver
# messages to consumer. If this number drops in percentage this may result
# in slower message delivery and indicate issues with the queue.
#
# Seeded from check-rabbitmq-consumers.rb
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
class CheckRabbitMQConsumerUtilisation < Sensu::Plugin::RabbitMQ::Check
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
         short: '-w CONSUMER_UTILISATION',
         long: '--warn CONSUMER_UTILISATION',
         proc: proc(&:to_f),
         description: 'WARNING consumer utilisation threshold',
         default: 0.9

  option :critical,
         short: '-c CONSUMER_UTILISATION',
         long: '--critical CONSUMER_UTILISATION',
         description: 'CRITICAL consumer utilisation threshold',
         proc: proc(&:to_f),
         default: 0.5

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
    # create arrays to hold failures
    queue_list = queue_list_builder(config[:queue])
    exclude_list = queue_list_builder(config[:exclude])
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
        consumer_util = queue['consumer_utilisation'] || 0
        critical.push("#{queue['name']}:#{consumer_util.round(2) * 100}%") if consumer_util <= config[:critical]
        warn.push("#{queue['name']}:#{consumer_util.round(2) * 100}%") if consumer_util <= config[:warn]
      end
    rescue StandardError
      critical 'Could not find any queue, check rabbitmq server'
    end
    return_condition(missing, critical, warn)
  end
end
