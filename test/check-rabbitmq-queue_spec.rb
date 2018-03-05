#!/usr/bin/env ruby
# frozen_string_literal: false

#
# check-rabbitmq-queue_spec
#
# DESCRIPTION:
#   Tests for check-rabbitmq-queue.rb
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
require_relative '../bin/check-rabbitmq-queue.rb'

def cq1
  {
    'name' => 'q1',
    'messages' => 700
  }
end

def cq2
  {
    'name' => 'q2',
    'messages' => 300
  }
end

class RabbitInfoStub
end

describe CheckRabbitMQQueue, 'run' do
  let(:check) do
    CheckRabbitMQQueue.new ['--queue', 'q1,q2']
  end

  it 'should return a warning when the queue does not exist' do
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return []
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:warning)

    check.run
  end

  it 'should return a warning when the number of messages exceeds the default threshold of 250' do
    check.config[:ignore] = true
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [cq2]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:warning)

    check.run
  end

  it 'should return a critical when the number of messages exceeds the default threshold of 500' do
    check.config[:ignore] = true
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [cq1]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical)

    check.run
  end

  it 'should return a critical when below is true and the number of messages is below the threshold' do
    check.config[:ignore] = true
    check.config[:below] = true
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [cq2]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical)

    check.run
  end
end
