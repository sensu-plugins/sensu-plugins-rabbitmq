#!/usr/bin/env ruby

#
# RabbitMQ Network Partitions Check
# ===
#
# DESCRIPTION:
# This plugin checks if a RabbitMQ network partition has occured.
# https://www.rabbitmq.com/partitions.html
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
# Copyright 2015 Ed Robinson <ed@reevoo.com> and Reevoo LTD.
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'
require 'carrot-top'
require 'inifile'

# main plugin class
class CheckRabbitMQPartitions < Sensu::Plugin::Check::CLI
  option :host,
         description: 'RabbitMQ management API host',
         short: '-w',
         long: '--host HOST',
         default: 'localhost'

  option :port,
         description: 'RabbitMQ management API port',
         long: '--port PORT',
         proc: proc(&:to_i),
         default: 15_672

  option :username,
         description: 'RabbitMQ management API user',
         short: '-u',
         long: '--username USERNAME',
         default: 'guest'

  option :password,
         description: 'RabbitMQ management API password',
         short: '-p',
         long: '--password PASSWORD',
         default: 'guest'

  option :ssl,
         description: 'Enable SSL for connection to the API',
         long: '--ssl',
         boolean: true,
         default: false

  option :ini,
         description: 'Configuration ini file',
         short: '-i',
         long: '--ini VALUE'

  def run
    critical 'network partition detected' if partition?
    ok 'no network partition detected'
  rescue Errno::ECONNREFUSED => e
    critical e.message
  rescue StandardError => e
    unknown e.message
  end

  def partition?
    rabbitmq_management.nodes.map { |node| node['partitions'] }.any?(&:any?)
  end

  def rabbitmq_management
    if config[:ini]
      ini = IniFile.load(config[:ini])
      section = ini['auth']
      username = section['username']
      password = section['password']
    else
      username = config[:username]
      password = config[:password]
    end

    CarrotTop.new(
      host: config[:host],
      port: config[:port],
      user: username,
      password: password,
      ssl: config[:ssl]
    )
  end
end
