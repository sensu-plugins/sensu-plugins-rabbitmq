#!/usr/bin/env ruby -W0
# frozen_string_literal: true

#
# RabbitMQ check node health plugin
# ===
#
# DESCRIPTION:
#   This plugin checks if RabbitMQ server node is in a running state.
#
#   The plugin is based on the RabbitMQ cluster node health plugin by Tim Smith
#   Edited my Milos Dodic and Milos Buncic (2016/10/27)
#
# USAGE:
#   "check-rabbitmq-node-usage.rb -w host --username user --password pass --type mem -m 50 -c 90"
#
# NOTES:
#   Use of "type" is mandatory. The script will check only the specified type.
#
# PLATFORMS:
#   Linux, Windows, BSD, Solaris
#
# DEPENDENCIES:
#   RabbitMQ rabbitmq_management plugin
#   gem: sensu-plugin
#   gem: carrot-top
#
# LICENSE:
# Copyright 2012 Abhijith G <abhi@runa.com> and Runa Inc.
# Copyright 2014 Tim Smith <tim@cozy.co> and Cozy Services Ltd.
# Copyright 2015 Edward McLain <ed@edmclain.com> and Daxko, LLC.
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/check/cli'
require 'carrot-top'
require 'inifile'

# Main plugin class
class CheckRabbitMQNodeUsage < Sensu::Plugin::Check::CLI
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

  option :ssl,
         description: 'Enable SSL for connection to the API',
         long: '--ssl',
         boolean: true,
         default: false

  option :type,
         description: 'Resource type',
         required: true,
         long: '--type TYPE',
         in: %w[mem socket fd proc disk]

  option :memwarn,
         description: 'Warning % of mem usage vs high watermark',
         short: '-m',
         long: '--mwarn PERCENT',
         proc: proc(&:to_f),
         default: 80

  option :memcrit,
         description: 'Critical % of mem usage vs high watermark',
         short: '-c',
         long: '--mcrit PERCENT',
         proc: proc(&:to_f),
         default: 90

  option :fdwarn,
         description: 'Warning % of file descriptor usage vs high watermark',
         short: '-f',
         long: '--fwarn PERCENT',
         proc: proc(&:to_f),
         default: 80

  option :fdcrit,
         description: 'Critical % of file descriptor usage vs high watermark',
         short: '-F',
         long: '--fcrit PERCENT',
         proc: proc(&:to_f),
         default: 90

  option :socketwarn,
         description: 'Warning % of socket usage vs high watermark',
         short: '-s',
         long: '--swarn PERCENT',
         proc: proc(&:to_f),
         default: 80

  option :socketcrit,
         description: 'Critical % of socket usage vs high watermark',
         short: '-S',
         long: '--scrit PERCENT',
         proc: proc(&:to_f),
         default: 90

  option :procwarn,
         description: 'Warning % of proc usage vs high watermark',
         short: '-e',
         long: '--pwarn PERCENT',
         proc: proc(&:to_f),
         default: 80

  option :proccrit,
         description: 'Critical % of proc usage vs high watermark',
         short: '-E',
         long: '--pcrit PERCENT',
         proc: proc(&:to_f),
         default: 90

  option :diskwarn,
         description: 'Warning % of disk usage vs high watermark',
         short: '-d',
         long: '--dwarn PERCENT',
         proc: proc(&:to_f),
         default: 80

  option :diskcrit,
         description: 'Critical % of disk usage vs high watermark',
         short: '-D',
         long: '--dcrit PERCENT',
         proc: proc(&:to_f),
         default: 90

  option :ini,
         description: 'Configuration ini file',
         short: '-i',
         long: '--ini VALUE'

  def run
    res = node_healthy?

    if res['status'] == 'ok'
      ok res['message']
    elsif res['status'] == 'warning'
      warning res['message']
    elsif res['status'] == 'critical'
      critical res['message']
    else
      unknown res['message']
    end
  end

  def node_healthy?
    # Checks and shows usage (for the specified type only). Shows usage for ok status as well.
    case config[:type]
    when 'mem'
      output = node_mem
    when 'socket'
      output = node_socket
    when 'fd'
      output = node_fd
    when 'proc'
      output = node_proc
    when 'disk'
      output = node_disk
    end

    { 'status' => output[:status], 'message' => output[:message] }
  rescue StandardError => e
    { 'status' => 'unknown', 'message' => e.message }
  end

  def node_mem
    pmem = node_info[:pmem]

    output = {}

    if pmem.to_f >= config[:memcrit]
      output[:message] = "Memory usage is critical: #{pmem}%"
      output[:status] = 'critical'
    elsif pmem.to_f >= config[:memwarn]
      output[:message] = "Memory usage is at warning: #{pmem}%"
      output[:status] = 'warning'
    elsif pmem.to_f < config[:memwarn]
      output[:message] = "Memory usage is at: #{pmem}%"
      output[:status] = 'ok'
    end

    output
  end

  def node_socket
    psocket = node_info[:psocket]

    output = {}

    if psocket.to_f >= config[:socketcrit]
      output[:message] = "Socket usage is critical: #{psocket}%"
      output[:status] = 'critical'
    elsif psocket.to_f >= config[:socketwarn]
      output[:message] = "Socket usage is at warning: #{psocket}%"
      output[:status] = 'warning'
    elsif psocket.to_f < config[:socketwarn]
      output[:message] = "Socket usage is at: #{psocket}%"
      output[:status] = 'ok'
    end

    output
  end

  def node_fd
    pfd = node_info[:pfd]

    output = {}

    if pfd.to_f >= config[:fdcrit]
      output[:message] = "File Descriptor usage is critical: #{pfd}%"
      output[:status] = 'critical'
    elsif pfd.to_f >= config[:fdwarn]
      output[:message] = "File Descriptor usage is at warning: #{pfd}%"
      output[:status] = 'warning'
    elsif pfd.to_f < config[:fdwarn]
      output[:message] = "File Descriptor usage is at: #{pfd}%"
      output[:status] = 'ok'
    end

    output
  end

  def node_proc
    pproc = node_info[:pproc]

    output = {}

    if pproc.to_f >= config[:proccrit]
      output[:message] = "Proc usage is critical: #{pproc}%"
      output[:status] = 'critical'
    elsif pproc.to_f >= config[:procwarn]
      output[:message] = "Proc usage is at warning: #{pproc}%"
      output[:status] = 'warning'
    elsif pproc.to_f < config[:procwarn]
      output[:message] = "Proc usage is at: #{pproc}%"
      output[:status] = 'ok'
    end

    output
  end

  def node_disk
    pdisk = node_info[:pdisk]

    output = {}

    if pdisk.to_f >= config[:diskcrit]
      output[:message] = "Disk usage is critical: #{pdisk}%"
      output[:status] = 'critical'
    elsif pdisk.to_f >= config[:diskwarn]
      output[:message] = "Disk usage is at warning: #{pdisk}%"
      output[:status] = 'warning'
    elsif pdisk.to_f < config[:diskwarn]
      output[:message] = "Disk usage is at: #{pdisk}%"
      output[:status] = 'ok'
    end

    output
  end

  def node_info
    # Parse the data
    nodeinfo = rabbitmq_management.nodes[0]

    output = {}

    # Determine % memory consumed
    output[:pmem] = format('%.2f', nodeinfo['mem_used'].fdiv(nodeinfo['mem_limit']) * 100)
    # Determine % sockets consumed
    output[:psocket] = format('%.2f', nodeinfo['sockets_used'].fdiv(nodeinfo['sockets_total']) * 100)
    # Determine % file descriptors consumed
    output[:pfd] = format('%.2f', nodeinfo['fd_used'].fdiv(nodeinfo['fd_total']) * 100)
    # Determine % proc consumed
    output[:pproc] = format('%.2f', nodeinfo['proc_used'].fdiv(nodeinfo['proc_total']) * 100)
    # Determine % disk consumed
    output[:pdisk] = format('%.2f', nodeinfo['disk_free_limit'].fdiv(nodeinfo['disk_free']) * 100)

    output
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
