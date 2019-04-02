#!/usr/bin/env ruby
# frozen_string_literal: true

#
# RabbitMQ Queue Drain Time
# ===
#
# DESCRIPTION:
# This plugin checks the time it will take for each queue on the RabbitMQ
# server to drain based on the current message egress rate.  For example
# if a queue has 1,000 messages in it, but egresses only 1 message a sec
# the alert would fire as this is greater than the default critical level of 360s
#
# The plugin is based on the RabbitMQ Queue Metrics plugin
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
# Copyright 2015 Tim Smith <tim@cozy.co> and Cozy Services Ltd.
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'
require 'socket'
require 'carrot-top'
require 'inifile'

# main plugin class
class CheckRabbitMQQueueDrainTime < Sensu::Plugin::Check::CLI
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

  option :filter,
         description: 'Regular expression for filtering queues',
         long: '--filter REGEX',
         default: '.*'

  option :ssl,
         description: 'Enable SSL for connection to the API',
         long: '--ssl',
         boolean: true,
         default: false

  option :warn,
         short: '-w PROCESS_TIME_SECS',
         long: '--warning PROCESS_TIME_SECS',
         description: 'WARNING that messages will process at current rate',
         default: 180

  option :critical,
         short: '-c PROCESS_TIME_SECS',
         long: '--critical PROCESS_TIME_SECS',
         description: 'CRITICAL time that messages will process at current rate',
         default: 360

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
    rescue StandardError
      warning 'could not get rabbitmq queue info'
    end

    queues = rabbitmq_info.queues.select { |q| q['name'].match(Regexp.new(config[:filter])) }

    if config[:vhost]
      return queues.select { |x| x['vhost'].match(config[:vhost]) }
    end

    queues
  end

  def run
    warn_queues = {}
    crit_queues = {}

    acquire_rabbitmq_queues.each do |queue|
      # we don't care about empty queues and they'll have an infinite drain time so skip them
      next if queue['messages'].nil? || queue['messages'].zero?

      # handle rate of zero which is an infinite time until empty
      if queue['backing_queue_status']['avg_egress_rate'].to_f.zero?
        crit_queues[queue['name']] = 'Infinite (drain rate = 0)'
        next
      end

      secs_till_empty = queue['messages'] / queue['backing_queue_status']['avg_egress_rate']

      # place warn / crit counts into hashes to be parsed for the alert message
      if secs_till_empty > config[:critical].to_i
        crit_queues[queue['name']] = secs_till_empty
      elsif secs_till_empty > config[:warn].to_i
        warn_queues[queue['name']] = secs_till_empty
      end
    end

    # decide if we need to alert and build the message
    if !crit_queues.empty?
      critical "Drain time: #{crit_queues.map { |q, c| "#{q} #{c} sec" }.join(', ')}"
    elsif !warn_queues.empty?
      warning "Drain time: #{warn_queues.map { |q, c| "#{q} #{c} sec" }.join(', ')}"
    else
      ok "All (#{acquire_rabbitmq_queues.count}) queues will be drained in under #{config[:warn].to_i} seconds"
    end
  end
end
