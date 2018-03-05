#!/usr/bin/env ruby
# frozen_string_literal: true

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

require 'sensu-plugins-rabbitmq'

# main plugin class
class RabbitMQExchangeMetrics < Sensu::Plugin::RabbitMQ::Metrics
  option :filter,
         description: 'Regular expression for filtering exchanges',
         long: '--filter REGEX'

  option :metrics,
         description: 'Regular expression for filtering metrics in each exchange',
         long: '--metrics REGEX'

  def run
    timestamp = Time.now.to_i
    acquire_rabbitmq_info(:exchanges).each do |exchange|
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
