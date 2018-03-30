#!/usr/bin/env ruby
# frozen_string_literal: true

#
# check-rabbitmq-queues-synchronised_spec
#
# DESCRIPTION:
#   Tests for check-rabbitmq-queues-synchronised.rb
#
# OUTPUT:
#
# PLATFORMS:
#
# DEPENDENCIES:
#
# USAGE:
#   bundle install
#   bundle exec rake spec
#
# NOTES:
#
# LICENSE:
#   Copyright 2017 Cyril Gaudin <cyril.gaudin@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE for details.

require_relative './spec_helper.rb'
require_relative '../bin/check-rabbitmq-queues-synchronised.rb'

json_ok = '[
    {
        "name": "test_queue1",
        "node": "rabbit@node1",
        "policy": "HA",
        "slave_nodes": [
            "rabbit@node2"
        ],
        "state": "running",
        "synchronised_slave_nodes": [
            "rabbit@node2"
        ],
        "vhost": "/"
    },
    {
        "name": "test_queue2",
        "node": "rabbit@node2",
        "policy": "HA",
        "slave_nodes": [
            "rabbit@node1"
        ],
        "state": "running",
        "synchronised_slave_nodes": [
            "rabbit@node1"
        ],
        "vhost": "/"
    }
]'

json_nok1 = '[
    {
        "name": "test_queue1",
        "node": "rabbit@node1",
        "policy": "HA",
        "slave_nodes": [
            "rabbit@node2"
        ],
        "state": "running",
        "synchronised_slave_nodes": [],
        "vhost": "/"
    },
    {
        "name": "test_queue2",
        "node": "rabbit@node2",
        "policy": "HA",
        "slave_nodes": [
            "rabbit@node1"
        ],
        "state": "running",
        "synchronised_slave_nodes": [
            "rabbit@node1"
        ],
        "vhost": "/"
    }
]'

json_nok2 = '[
    {
        "name": "test_queue1",
        "node": "rabbit@node1",
        "policy": "HA",
        "slave_nodes": [
            "rabbit@node2"
        ],
        "state": "running",
        "synchronised_slave_nodes": [],
        "vhost": "/"
    },
    {
        "name": "test_queue2",
        "node": "rabbit@node2",
        "policy": "HA",
        "slave_nodes": [
            "rabbit@node1"
        ],
        "state": "running",
        "synchronised_slave_nodes": [],
        "vhost": "/"
    }
]'

json_nok3 = '[
    {
        "name": "test_queue1",
        "node": "rabbit@node1",
        "policy": "HA",
        "slave_nodes": [
            "rabbit@node2",
            "rabbit@node3",
            "rabbit@node4"
        ],
        "state": "running",
        "synchronised_slave_nodes": [
            "rabbit@node2"
        ],
        "vhost": "/"
    }
]'

json_ok_not_mirrored = '[
    {
        "name": "test_queue1",
        "node": "rabbit@node1",
        "policy": "HA",
        "state": "running",
        "vhost": "/"
    }
]'

json_no_queue = '[]'

bad_json = '{}{}'

describe CheckRabbitMQQueuesSynchronised, 'run' do
  let(:check) do
    CheckRabbitMQQueuesSynchronised.new
  end

  let(:listCheck) do
    CheckRabbitMQQueuesSynchronised.new ['--list-queues']
  end

  it 'should be ok with synchronised queues' do
    resource = double
    allow(resource).to receive(:get) { json_ok }
    allow(RestClient::Resource).to receive(:new) { resource }
    expect(check).not_to receive(:critical)
    expect(check).not_to receive(:unknown)
    expect(check).to receive(:ok)

    check.run
  end

  it 'should be critical with one unsynchronised queue' do
    resource = double
    allow(resource).to receive(:get) { json_nok1 }
    allow(RestClient::Resource).to receive(:new) { resource }
    expect(check).not_to receive(:ok)
    expect(check).not_to receive(:unknown)
    expect(check).to receive(:critical).with('1 unsynchronised queue(s)')

    check.run

    expect(listCheck).not_to receive(:ok)
    expect(listCheck).not_to receive(:unknown)
    expect(listCheck).to receive(:critical).with('test_queue1: 1 unsynchronised slave(s)')

    listCheck.run
  end

  it 'should be critical with a partially unsynchronised queues' do
    resource = double
    allow(resource).to receive(:get) { json_nok2 }
    allow(RestClient::Resource).to receive(:new) { resource }
    expect(check).not_to receive(:ok)
    expect(check).not_to receive(:unknown)
    expect(check).to receive(:critical).with('2 unsynchronised queue(s)')

    check.run

    expect(listCheck).not_to receive(:ok)
    expect(listCheck).not_to receive(:unknown)
    expect(listCheck).to receive(:critical).with('test_queue1: 1 unsynchronised slave(s) - test_queue2: 1 unsynchronised slave(s)')

    listCheck.run
  end

  it 'should be critical with two unsynchronised queues' do
    resource = double
    allow(resource).to receive(:get) { json_nok3 }
    allow(RestClient::Resource).to receive(:new) { resource }
    expect(check).not_to receive(:ok)
    expect(check).not_to receive(:unknown)
    expect(check).to receive(:critical).with('1 unsynchronised queue(s)')

    check.run

    expect(listCheck).not_to receive(:ok)
    expect(listCheck).not_to receive(:unknown)
    expect(listCheck).to receive(:critical).with('test_queue1: 2 unsynchronised slave(s)')

    listCheck.run
  end

  it 'should be ok with not mirrored queues' do
    resource = double
    allow(resource).to receive(:get) { json_ok_not_mirrored }
    allow(RestClient::Resource).to receive(:new) { resource }
    expect(check).to receive(:ok)
    expect(check).not_to receive(:unknown)
    expect(check).not_to receive(:critical)

    check.run
  end

  it 'should be ok without queue' do
    resource = double
    allow(resource).to receive(:get) { json_no_queue }
    allow(RestClient::Resource).to receive(:new) { resource }
    expect(check).to receive(:ok)
    expect(check).not_to receive(:unknown)
    expect(check).not_to receive(:critical)

    check.run
  end

  it 'should be unknown with bad json' do
    resource = double
    allow(resource).to receive(:get) { bad_json }
    allow(RestClient::Resource).to receive(:new) { resource }
    expect(check).not_to receive(:ok)
    expect(check).to receive(:unknown)
    expect(check).not_to receive(:critical)

    check.run
  end

  it 'should set the verify_ssl param to true by default' do
    resource = double

    allow(resource).to receive(:get) { json_ok }
    allow(RestClient::Resource).to receive(:new) do |_, options|
      expect(options[:verify_ssl]).to eql(true)
      resource
    end

    expect(check).to receive(:ok)

    check.run
  end

  it 'allows overriding the verify_ssl param' do
    check = CheckRabbitMQQueuesSynchronised.new ['--verify_ssl_off']
    resource = double

    allow(resource).to receive(:get) { json_ok }
    allow(RestClient::Resource).to receive(:new) do |_, options|
      expect(options[:verify_ssl]).to eql(false)
      resource
    end

    expect(check).to receive(:ok)

    check.run
  end
end
