#!/usr/bin/env ruby
# frozen_string_literal: true

#
# metrics-rabbitmq-queue_spec
#
# DESCRIPTION:
#   Tests for metrics-rabbitmq-queue.rb
#
# OUTPUT:
#
# PLATFORMS:
#
# DEPENDENCIES:
#
# USAGE:
#   bundle install
#   rake spec
#
# NOTES:
#
# LICENSE:
#   Copyright 2017 Romain Thouvenin <romain@thouvenin.pro>
#   Released under the same terms as Sensu (the MIT license); see LICENSE for details.

require_relative './spec_helper.rb'
require_relative '../bin/metrics-rabbitmq-queue.rb'

def q1
  {
    'name' => 'q1',
    'messages' => 42,
    'consumers' => 1,
    'backing_queue_status' => { 'avg_egress_rate' => 4.2 }
  }
end

def q2
  {
    'name' => 'q2',
    'memory' => 666,
    'state' => 'running',
    'messages' => 0,
    'consumers' => 0,
    'backing_queue_status' => { 'avg_egress_rate' => 0.123456e-123 },
    'message_details' => { 'messages_ready' => 0 }
  }
end

describe RabbitMQQueueMetrics, 'run' do
  let(:check) do
    RabbitMQQueueMetrics.new
  end

  it 'should output nothing and return ok when there are no queues' do
    allow(check).to receive(:acquire_rabbitmq_info).and_return []
    expect(check).not_to receive(:output)
    expect(check).to receive(:ok)
    check.run
  end

  it 'should by default output all queues and a spefific set of metrics' do
    allow(check).to receive(:acquire_rabbitmq_info).and_return [q1, q2]

    expect(check).to receive(:output).with(/.+.rabbitmq.q1.messages$/, 42, timestamp)
    expect(check).to receive(:output).with(/.+.rabbitmq.q1.consumers$/, 1, timestamp)
    expect(check).to receive(:output).with(/.+.rabbitmq.q1.avg_egress_rate$/, '4.2000', timestamp)
    expect(check).to receive(:output).with(/.+.rabbitmq.q1.drain_time$/, 10, timestamp)

    expect(check).to receive(:output).with(/.+.rabbitmq.q2.messages$/, 0, timestamp)
    expect(check).to receive(:output).with(/.+.rabbitmq.q2.consumers$/, 0, timestamp)
    expect(check).to receive(:output).with(/.+.rabbitmq.q2.avg_egress_rate$/, '0.0000', timestamp)
    expect(check).to receive(:output).with(/.+.rabbitmq.q2.drain_time$/, 0, timestamp)

    expect(check).to receive(:ok)
    check.run
  end

  it 'should output only the queues specified by the filter option' do
    check.config[:filter] = '.2'
    allow(check).to receive(:acquire_rabbitmq_info).and_return [q1, q2]
    expect(check).not_to receive(:output).with(/q1/, any_args)
    expect(check).to receive(:output).with(/q2/, any_args).exactly(4).times
    expect(check).to receive(:ok)
    check.run
  end

  it 'should output only the metrics specified by the metrics option' do
    check.config[:metrics] = 'message_details|consumers'
    allow(check).to receive(:acquire_rabbitmq_info).and_return [q2]
    expect(check).to receive(:output).with(/q2.consumers$/, 0, timestamp)
    expect(check).to receive(:output).with(/q2.message_details.messages_ready$/, 0, timestamp)
    expect(check).to receive(:ok)
    check.run
  end
end
