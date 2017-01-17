#!/usr/bin/env ruby
#  encoding: UTF-8
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

require 'sensu-plugin/check/cli'
require 'socket'
require 'carrot-top'

# main plugin class
class CheckRabbitMQMessages < Sensu::Plugin::Check::CLI
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
         description: 'RabbitMQ vhost',
         short: '-v',
         long: '--vhost VHOST',
         default: ''

  option :ssl,
         description: 'Enable SSL for connection to the API',
         long: '--ssl',
         boolean: true,
         default: false

  option :user,
         description: 'RabbitMQ management API user',
         long: '--user USER',
         default: 'guest'

  option :password,
         description: 'RabbitMQ management API password',
         long: '--password PASSWORD',
         default: 'guest'

  option :queue,
         description: 'RabbitMQ queue to monitor',
         long: '--queue queue_names',
         required: true,
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

  def acquire_rabbitmq_info
    begin
      rabbitmq_info = CarrotTop.new(
        host: config[:host],
        port: config[:port],
        user: config[:user],
        password: config[:password],
        ssl: config[:ssl]
      )
    rescue
      warning 'could not get rabbitmq info'
    end
    rabbitmq_info
  end

  def run
    @crit = []
    @warn = []
    rabbitmq = acquire_rabbitmq_info
    queues = rabbitmq.method_missing('/queues/' + config[:vhost])
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
