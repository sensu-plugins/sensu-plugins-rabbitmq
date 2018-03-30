#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Check RabbitMQ Queues Synchronised
# ===
#
# DESCRIPTION:
# This plugin checks that all mirrored queues which have slaves are synchronised.
#
# PLATFORMS:
#   Linux, BSD, Solaris
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#
# LICENSE:
# Copyright 2017 Cyril Gaudin <cyril.gaudin@gmail.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rest_client'
require 'sensu-plugins-rabbitmq'

# main plugin class
class CheckRabbitMQQueuesSynchronised < Sensu::Plugin::RabbitMQ::Check
  option :list_queues,
         description: 'If set, will ouput the list of all unsynchronised queues, otherwise only the count',
         long: '--list-queues',
         boolean: true,
         default: false

  option :verify_ssl_off,
         description: 'Do not check validity of SSL cert. Use for self-signed certs, etc (insecure)',
         long: '--verify_ssl_off',
         boolean: true,
         default: false

  def run
    @crits = []

    queues = get_queues config

    queues.each do |q|
      next unless q.key?('slave_nodes')

      nb_slaves = q['slave_nodes'].count
      next if nb_slaves.zero?
      unsynchronised = nb_slaves - q['synchronised_slave_nodes'].count
      if unsynchronised != 0
        @crits << "#{q['name']}: #{unsynchronised} unsynchronised slave(s)"
      end
    end
    if @crits.empty?
      ok
    elsif config[:list_queues]
      critical @crits.join(' - ')
    else
      critical "#{@crits.count} unsynchronised queue(s)"
    end
  rescue Errno::ECONNREFUSED => e
    critical e.message
  rescue StandardError => e
    unknown e.message
  end

  def get_queues(config)
    url_prefix = config[:ssl] ? 'https' : 'http'
    options = {
      user: config[:username],
      password: config[:password],
      verify_ssl: !config[:verify_ssl_off]
    }

    resource = RestClient::Resource.new(
      "#{url_prefix}://#{config[:host]}:#{config[:port]}/api/queues",
      options
    )
    JSON.parse(resource.get)
  end
end
