#!/usr/bin/env ruby
#
# metrics-rabbitmq-exchange_spec
#
# DESCRIPTION:
#   Tests for metrics-rabbitmq-exchange.rb
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
require_relative '../bin/metrics-rabbitmq-exchange.rb'

def e1
  {
    'name' => 'e1',
    'type' => 'topic',
    'durable' => 'true',
    'message_stats' => {'publish' => 100, 'ack' => 50}
  }
end

def e2
  {
    'name' => 'e2',
    'type' => 'fanout',
    'durable' => 'false'
  }
end

describe RabbitMQExchangeMetrics, 'run' do
  let(:check) do
    RabbitMQExchangeMetrics.new 
  end

  it "should output nothing and return ok when there are no exchanges" do
    allow(check).to receive(:acquire_rabbitmq_info).and_return []
    expect(check).not_to receive(:output)
    expect(check).to receive(:ok)
    check.run
  end

  it "should by default output all exchanges and all metrics" do
    allow(check).to receive(:acquire_rabbitmq_info).and_return [e1, e2]

    expect(check).to receive(:output).with(/.+.rabbitmq.e1.name$/, 'e1', timestamp)
    expect(check).to receive(:output).with(/.+.rabbitmq.e1.type$/, 'topic', timestamp)
    expect(check).to receive(:output).with(/.+.rabbitmq.e1.durable$/, 'true', timestamp)
    expect(check).to receive(:output).with(/.+.rabbitmq.e1.message_stats.publish$/, 100, timestamp)
    expect(check).to receive(:output).with(/.+.rabbitmq.e1.message_stats.ack$/, 50, timestamp)

    expect(check).to receive(:output).with(/.+.rabbitmq.e2.name$/, 'e2', timestamp)
    expect(check).to receive(:output).with(/.+.rabbitmq.e2.type$/, 'fanout', timestamp)
    expect(check).to receive(:output).with(/.+.rabbitmq.e2.durable$/, 'false', timestamp)

    expect(check).to receive(:ok)
    check.run
  end

  it "should output only the exchanges specified by the filter option" do
    check.config[:filter] = '.2'
    allow(check).to receive(:acquire_rabbitmq_info).and_return [e1, e2]
    expect(check).not_to receive(:output).with(/e1/, any_args)
    expect(check).to receive(:output).with(/e2/, any_args).exactly(e2.size).times
    expect(check).to receive(:ok)
    check.run
  end

  it "should output only the metrics specified by the metrics option" do
    check.config[:metrics] = 'message_stats'
    allow(check).to receive(:acquire_rabbitmq_info).and_return [e1]
    expect(check).to receive(:output).with(/e1.message_stats.publish$/, 100, timestamp)
    expect(check).to receive(:output).with(/e1.message_stats.ack$/, 50, timestamp)
    expect(check).to receive(:ok)
    check.run
  end

end 
