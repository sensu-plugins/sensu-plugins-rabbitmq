#!/usr/bin/env ruby
#  encoding: UTF-8
#
# RabbitMQ Queue Metrics
# ===
#
# DESCRIPTION:
# This plugin checks gathers the following per queue rabbitmq metrics:
#   - message count
#   - average egress rate
#   - "drain time" metric, which is the time a queue will take to reach 0 based on the egress rate
#   - consumer count
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
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/metric/cli'
require 'socket'
require 'carrot-top'

QUEUES_STATES_MAPS = {
  'running'  => 0,
  'starting' => 1,
  'tuning'   => 2,
  'opening'  => 3,
  'flow'     => 4,
  'blocking' => 5,
  'blocked'  => 6,
  'closing'  => 7,
  'closed'   => 8
}
# main plugin class
class RabbitMQMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :host,
         description: 'RabbitMQ management API host',
         long: '--host HOST',
         default: 'localhost'

  option :port,
         description: 'RabbitMQ management API port',
         long: '--port PORT',
         proc: proc(&:to_i),
         default: 15_672

  option :user,
         description: 'RabbitMQ management API user',
         long: '--user USER',
         default: 'guest'

  option :password,
         description: 'RabbitMQ management API password',
         long: '--password PASSWORD',
         default: 'guest'

  option :scheme,
         description: 'Metric naming scheme, text to prepend to $queue_name.$metric',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.rabbitmq"

  option :filter,
         description: 'Regular expression for filtering queues',
         long: '--filter REGEX'

  option :exclude,
         description: 'Regular expression for excluding queues',
         long: '--exclude REGEX'

  option :ssl,
         description: 'Enable SSL for connection to the API',
         long: '--ssl',
         boolean: true,
         default: false

  def acquire_rabbitmq_queues_and_conns
    queues_and_conns = {}
    begin
      rabbitmq_info = CarrotTop.new(
        host: config[:host],
        port: config[:port],
        user: config[:user],
        password: config[:password],
        ssl: config[:ssl]
      )
    rescue
      warning 'Could not get rabbitmq info'
    end
    queues_and_conns['queues'] = rabbitmq_info.queues
    queues_and_conns['conns'] = rabbitmq_info.connections
    queues_and_conns
  end

  def run
    timestamp = Time.now.to_i

    # Per node connection metrics
    nodes_conn_states = {}
    acquire_rabbitmq_queues_and_conns['conns'].each do |con|
      node_name = con['node']
      conn_state = con['state']
      if nodes_conn_states.key?(node_name)
        if nodes_conn_states[node_name].key?(conn_state)
          nodes_conn_states[node_name][conn_state] = nodes_conn_states[node_name][conn_state] + 1
        else
          nodes_conn_states[node_name][conn_state] = 1
        end
      else
        nodes_conn_states[node_name] = {}
        nodes_conn_states[node_name][conn_state] = 1
      end
    end
    nodes_conn_states.each do |node, states|
      node_name = node.split('@')[1]
      states.each do |state, total|
        output([config[:scheme], 'conns_per_node', node_name, state].join('.'), total, timestamp)
      end
    end

    # Queues metrics
    acquire_rabbitmq_queues_and_conns['queues'].each do |queue|
      if config[:filter]
        next unless queue['name'].match(config[:filter])
      end

      if config[:exclude]
        next if queue['name'].match(config[:exclude])
      end
      output([config[:scheme], 'per_queue', queue['name'], 'state'].join('.'), QUEUES_STATES_MAPS[queue['state']], timestamp)
      output([config[:scheme], 'per_queue', queue['name'], 'messages_details_rate'].join('.'), queue['messages_details']['rate'], timestamp)
      output([config[:scheme], 'per_queue', queue['name'], 'backing_queue_status', 'avg_ingress_rate'].join('.'), queue['backing_queue_status']['avg_ingress_rate'], timestamp)
      output([config[:scheme], 'per_queue', queue['name'], 'consumers'].join('.'), queue['consumers'], timestamp)
      output([config[:scheme], 'per_queue', queue['name'], 'memory'].join('.'), queue['memory'], timestamp)
      # fetch the average egress rate of the queue
      rate = format('%.4f', queue['backing_queue_status']['avg_egress_rate'])
      output([config[:scheme], 'per_queue', queue['name'], 'avg_egress_rate'].join('.'), rate, timestamp)
      begin
        queue['consumer_utilisation'].empty?
      rescue
        output([config[:scheme], 'per_queue', queue['name'], 'consumer_utilization'].join('.'), queue['consumer_utilisation'], timestamp)
      end

      # calculate and output time till the queue is drained in drain metrics
      drain_time_divider = queue['backing_queue_status']['avg_egress_rate']
      if drain_time_divider != 0
        drain_time = queue['messages'] / drain_time_divider
        drain_time = 0 if drain_time.nan? # 0 rate with 0 messages is 0 time to drain
        output([config[:scheme], 'per_queue', queue['name'], 'drain_time'].join('.'), drain_time.to_i, timestamp)
      end

      %w(messages).each do |metric|
        output([config[:scheme],'per_queue', queue['name'], metric].join('.'), queue[metric], timestamp)
      end
    end
    ok
  end
end
