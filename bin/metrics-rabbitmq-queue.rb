#!/usr/bin/env ruby
# frozen_string_literal: true

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

require 'sensu-plugins-rabbitmq'

# main plugin class
class RabbitMQQueueMetrics < Sensu::Plugin::RabbitMQ::Metrics
  option :filter,
         description: 'Regular expression for filtering queues',
         long: '--filter REGEX'

  option :metrics,
         description: 'Regular expression for filtering metrics in each queue',
         long: '--metrics REGEX',
         default: '^messages$|consumers|drain_time|avg_egress'

  def run
    timestamp = Time.now.to_i
    acquire_rabbitmq_info(:queues).each do |queue|
      # The queue might be reported by the API but its metrics somehow
      # "corrupted". In this case, it doesn't have the ``backing_queue_status``
      # attribute set.
      next unless queue['backing_queue_status']

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
