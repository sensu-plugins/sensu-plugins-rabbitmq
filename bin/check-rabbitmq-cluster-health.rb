#!/usr/bin/env ruby
# frozen_string_literal: true

#
# RabbitMQ check cluster nodes health plugin
# ===
#
# DESCRIPTION:
# This plugin checks if RabbitMQ server's cluster nodes are in a running state.
# It also accepts and optional list of nodes and verifies that those nodes are
# present in the cluster.
# The plugin is based on the RabbitMQ alive plugin by Abhijith G.
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
# Copyright 2014 Tim Smith <tim@cozy.co> and Cozy Services Ltd.
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'
require 'json'
require 'rest_client'
require 'inifile'

# main plugin class
class CheckRabbitMQCluster < Sensu::Plugin::Check::CLI
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
         description: 'RabbitMQ API port',
         short: '-P',
         long: '--port PORT',
         default: '15672'

  option :nodes,
         description: 'Optional comma separated list of expected nodes in the cluster',
         short: '-n',
         long: '--nodes NODE1,NODE2',
         default: ''

  option :ssl,
         description: 'Enable SSL for connection to the API',
         long: '--ssl',
         boolean: true,
         default: false

  option :verify_ssl_off,
         description: 'Do not check validity of SSL cert. Use for self-signed certs, etc (insecure)',
         long: '--verify_ssl_off',
         boolean: true,
         default: false

  option :ssl_ca_file,
         description: 'Path to SSL CA .crt',
         long: '--ssl_ca_file CA_PATH',
         default: ''

  option :ini,
         description: 'Configuration ini file',
         short: '-i',
         long: '--ini VALUE'

  def run
    res = cluster_healthy?

    if res['status'] == 'ok'
      ok res['message']
    elsif res['status'] == 'critical'
      critical res['message']
    else
      unknown res['message']
    end
  end

  def missing_nodes?(nodes, servers_status)
    missing = []
    if nodes.empty?
      missing
    else
      nodes.reject { |x| servers_status.keys.include?(x) }
    end
  end

  def failed_nodes?(servers_status)
    failed_nodes = []
    servers_status.each { |sv, stat| failed_nodes << sv unless stat == true }
    failed_nodes
  end

  def cluster_healthy?
    host        = config[:host]
    port        = config[:port]
    ssl         = config[:ssl]
    verify_ssl  = config[:verify_ssl_off]
    nodes       = config[:nodes].split(',')
    ssl_ca_file = config[:ssl_ca_file]
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
      url_prefix = ssl ? 'https' : 'http'
      options = {
        user: username,
        password: password,
        verify_ssl: !verify_ssl
      }
      options[:ssl_ca_file] = ssl_ca_file unless ssl_ca_file.empty?

      resource = RestClient::Resource.new(
        "#{url_prefix}://#{host}:#{port}/api/nodes",
        options
      )
      # create a hash of the server names and their running state
      servers_status = Hash[JSON.parse(resource.get).map { |server| [server['name'], server['running']] }]

      # true or false for health of the nodes
      missing_nodes = missing_nodes?(nodes, servers_status)

      # array of nodes that are not running
      failed_nodes = failed_nodes?(servers_status)

      # build status and message
      status = failed_nodes.empty? && missing_nodes.empty? ? 'ok' : 'critical'
      message = if failed_nodes.empty?
                  "#{servers_status.keys.count} healthy cluster nodes"
                else
                  "#{failed_nodes.count} failed cluster node: #{failed_nodes.sort.join(',')}"
                end
      message.prepend("#{missing_nodes.count} node(s) not found: #{missing_nodes.join(',')}. ") unless missing_nodes.empty?
      { 'status' => status, 'message' => message }
    rescue Errno::ECONNREFUSED => e
      { 'status' => 'critical', 'message' => e.message }
    rescue StandardError => e
      { 'status' => 'unknown', 'message' => e.message }
    end
  end
end
