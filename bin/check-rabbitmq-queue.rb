#!/usr/bin/env ruby
# frozen_string_literal: false

#
# Check RabbitMQ Queue Messages
# ===
#
# DESCRIPTION:
# This plugin checks the number of messages queued on the RabbitMQ server in a specific queues
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
# Copyright 2012 Evan Hazlett <ejhazlett@gmail.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugins-rabbitmq'
require 'sensu-plugins-rabbitmq/check'
require 'sensu-plugin/check/cli'

# main plugin class
class CheckRabbitMQQueue < Sensu::Plugin::RabbitMQ::Check
  option :queue,
         description: 'RabbitMQ queue to monitor',
         long: '--queue queue_names',
         required: true,
         # not sure if there is a better way to handle frozen strings
         proc: proc { |a| a.split(',') }

  option :warn,
         short: '-w NUM_MESSAGES',
         long: '--warn NUM_MESSAGES',
         description: 'WARNING message count threshold',
         default: 250

  option :critical,
         short: '-c NUM_MESSAGES',
         long: '--critical NUM_MESSAGES',
         description: 'CRITICAL message count threshold',
         default: 500

  option :ignore,
         description: 'Ignore non-existent queues',
         long: '--ignore',
         boolean: true,
         default: false

  option :regex,
         description: 'Use queue name as regex pattern',
         long: '--regex',
         boolean: true,
         default: false

  option :pretty,
         description: 'Prints multiline message',
         long: '--pretty',
         boolean: true,
         default: false

  option :below,
         description: 'If set, values under threshold are counted as warning/critical',
         long: '--below',
         boolean: true,
         default: false

  def run
    @crit = []
    @warn = []
    rabbitmq = acquire_rabbitmq_info
    queues = rabbitmq.method_missing('queues/' + config[:vhost])
    config[:queue].each do |q|
      unless (queues.map { |hash| hash['name'] }.include?(q) && config[:regex] == false) || config[:regex] == true
        unless config[:ignore]
          @warn << "Queue #{q} not available"
        end
        next
      end
      queues.each do |queue|
        next unless (queue['name'] == q && config[:regex] == false) || (queue['name'] =~ /#{q}/ && config[:regex] == true)
        total = queue['messages']
        total = 0 if total.nil?
        message total.to_s
        assign_alerts(queue['name'], total)
      end
    end
    generate_output
  end

  def assign_alerts(queue_name, total)
    if config[:below]
      @crit << "#{queue_name}:#{total}" if total <= config[:critical].to_i
      @warn << "#{queue_name}:#{total}" if total <= config[:warn].to_i && total > config[:critical].to_i
    else
      @crit << "#{queue_name}:#{total}" if total >= config[:critical].to_i
      @warn << "#{queue_name}:#{total}" if total >= config[:warn].to_i && total < config[:critical].to_i
    end
  end

  def generate_output
    if @crit.empty? && @warn.empty?
      ok
    elsif !@crit.empty?
      @message_output = "\n" + 'critical:' + "\n" + @crit.join("\n") if config[:pretty]
      @message_output = "critical: #{@crit}" unless config[:pretty]
      unless @warn.empty?
        @message_output += "\n" + 'warning:' + "\n" + @warn.join("\n") if config[:pretty]
        @message_output += " warning: #{@warn}" unless config[:pretty]
      end
      critical @message_output
    elsif !@warn.empty?
      @message_output = "\n" + 'warning:' + "\n" + @warn.join("\n") if config[:pretty]
      @message_output = "warning: #{@warn}" unless config[:pretty]
      warning @message_output
    end
  end
end
