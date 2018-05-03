#!/usr/bin/env ruby
# frozen_string_literal: false

#
# check-rabbitmq-consumer-utilisation_spec
#
# DESCRIPTION:
#   Tests for check-rabbitmq-consumer-utilisation.rb
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
# Copyright 2018 Mike Murray <37150283+monkey670@users.noreply.github.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require_relative './spec_helper.rb'
require_relative '../bin/check-rabbitmq-consumer-utilisation.rb'

def queue1
  {
    'name' => 'q1',
    'consumer_utilisation' => 1
  }
end

def queue2
  {
    'name' => 'q2',
    'consumer_utilisation' => 0.23211730652213466
  }
end

def queue3
  {
    'name' => 'q3',
    'consumer_utilisation' => 0.772899906538027
  }
end

class RabbitInfoStub
end

describe CheckRabbitMQConsumerUtilisation, 'run' do
  let(:check) do
    CheckRabbitMQConsumerUtilisation.new ['--queue', 'q1,q2,q3']
  end

  it 'should return a warning when the queue does not exist' do
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return []
    allow(check).to receive(:rabbit).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical)

    check.run
  end

  it 'should return a ok when the utilisation percentage is above the default threshold of 0.9' do
    check = CheckRabbitMQConsumerUtilisation.new ['--queue', 'q1']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [queue1]
    allow(check).to receive(:rabbit).and_return info_stub

    expect(check).not_to receive(:critical)
    expect(check).not_to receive(:warning)
    expect(check).to receive(:ok)

    check.run
  end

  it 'should return a critical when the utilisation percentage is below the default threshold of 0.5' do
    check = CheckRabbitMQConsumerUtilisation.new ['--queue', 'q2']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [queue2]
    allow(check).to receive(:rabbit).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical)

    check.run
  end

  it 'should return a warning when the utilisation percentage is below the default threshold of 0.9' do
    check = CheckRabbitMQConsumerUtilisation.new ['--queue', 'q3']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [queue3]
    allow(check).to receive(:rabbit).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:warning)

    check.run
  end
end
