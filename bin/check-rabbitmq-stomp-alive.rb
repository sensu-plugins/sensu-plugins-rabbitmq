#!/usr/bin/env ruby
# frozen_string_literal: true

#
# RabbitMQ check alive plugin
# ===
#
# DESCRIPTION:
# This plugin checks if RabbitMQ server is alive and responding to STOMP
# requests.
#
# Based on rabbitmq-amqp-alive by Milos Gajdos
#
# PLATFORMS:
#   Linux, BSD, Solaris
#
# DEPENDENCIES:
#   RabbitMQ rabbitmq_management plugin
#   gem: sensu-plugin
#   gem: stomp
#
# LICENSE:
# Copyright 2014 Adam Ashley
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'
require 'stomp'
require 'inifile'

# main plugin class
class CheckRabbitStomp < Sensu::Plugin::Check::CLI
  option :host,
         description: 'RabbitMQ host',
         short: '-w',
         long: '--host HOST',
         default: 'localhost'

  option :username,
         description: 'RabbitMQ username',
         short: '-u',
         long: '--username USERNAME',
         default: 'guest'

  option :password,
         description: 'RabbitMQ password',
         short: '-p',
         long: '--password PASSWORD',
         default: 'guest'

  option :port,
         description: 'RabbitMQ STOMP port',
         short: '-P',
         long: '--port PORT',
         default: '61613'

  option :ssl,
         description: 'Enable SSL for connection to RabbitMQ',
         long: '--ssl',
         boolean: true,
         default: false

  option :queue,
         description: 'Queue to post a message to and receive from',
         short: '-q',
         long: '--queue QUEUE',
         default: 'aliveness-test'

  option :ini,
         description: 'Configuration ini file',
         short: '-i',
         long: '--ini VALUE'

  def run
    res = vhost_alive?

    if res['status'] == 'ok'
      ok res['message']
    elsif res['status'] == 'critical'
      critical res['message']
    else
      unknown res['message']
    end
  end

  def vhost_alive?
    if config[:ini]
      ini = IniFile.load(config[:ini])
      section = ini['auth']
      username = section['username']
      password = section['password']
    else
      username = config[:username]
      password = config[:password]
    end

    hash = {
      hosts: [
        {
          login: username,
          passcode: password,
          host: config[:host],
          port: config[:port],
          ssl: config[:ssl]
        }
      ],
      reliable: false, # disable failover
      connect_timeout: 10
    }

    begin
      conn = Stomp::Client.new(hash)
      conn.publish("/queue/#{config[:queue]}", 'STOMP Alive Test')
      conn.subscribe("/queue/#{config[:queue]}") do |_msg|
      end
      { 'status' => 'ok', 'message' => 'RabbitMQ server is alive' }
    rescue Errno::ECONNREFUSED
      { 'status' => 'critical', 'message' => 'TCP connection refused' }
    rescue Stomp::Error::BrokerException => e
      { 'status' => 'critical', 'message' => "Error from broker. Check auth details? #{e.message}" }
    rescue StandardError => e
      { 'status' => 'unknown', 'message' => "#{e.class}: #{e.message}" }
    end
  end
end
