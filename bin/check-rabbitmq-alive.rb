#!/usr/bin/env ruby
# frozen_string_literal: true

#
# RabbitMQ check alive plugin
# ===
#
# DESCRIPTION:
# This plugin checks if RabbitMQ server is alive using the REST API
#
# PLATFORMS:
#   Linux, Windows, BSD, Solaris
#
# DEPENDENCIES:
#   RabbitMQ rabbitmq_management plugin
#   gem: sensu-plugin
#   gem: rest-client
#
# LICENSE:
# Copyright 2012 Abhijith G <abhi@runa.com> and Runa Inc.
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'
require 'json'
require 'rest_client'
require 'inifile'

# main plugin class
class CheckRabbitMQAlive < Sensu::Plugin::Check::CLI
  option :host,
         description: 'RabbitMQ host',
         short: '-w',
         long: '--host HOST',
         default: 'localhost'

  option :vhost,
         description: 'RabbitMQ vhost',
         short: '-v',
         long: '--vhost VHOST',
         default: '%2F'

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
         description: 'RabbitMQ API port',
         short: '-P',
         long: '--port PORT',
         default: '15672'

  option :ssl,
         description: 'Enable SSL for connection to RabbitMQ',
         long: '--ssl',
         boolean: true,
         default: false

  option :verify_ssl_off,
         description: 'Do not check validity of SSL cert. Use for self-signed certs, etc (insecure)',
         long: '--verify_ssl_off',
         boolean: true,
         default: false

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
    host       = config[:host]
    port       = config[:port]
    vhost      = config[:vhost]
    ssl        = config[:ssl]
    verify_ssl = config[:verify_ssl_off]
    if config[:ini]
      ini = IniFile.load(config[:ini])
      section = ini['auth']
      username = section['username']
      password = section['password']
    else
      username = config[:username]
      password = config[:password]
    end

    begin
      resource = RestClient::Resource.new(
        "http#{ssl ? 's' : ''}://#{host}:#{port}/api/aliveness-test/#{vhost}",
        user: username,
        password: password,
        verify_ssl: !verify_ssl
      )
      # Attempt to parse response (just to trigger parse exception)
      _response = JSON.parse(resource.get) == { 'status' => 'ok' }
      { 'status' => 'ok', 'message' => 'RabbitMQ server is alive' }
    rescue Errno::ECONNREFUSED => e
      { 'status' => 'critical', 'message' => e.message }
    rescue StandardError => e
      { 'status' => 'unknown', 'message' => e.message }
    end
  end
end
