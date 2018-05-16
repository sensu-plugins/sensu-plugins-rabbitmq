#!/usr/bin/env ruby
# frozen_string_literal: false

#
# check-rabbitmq-consumers_spec
#
# DESCRIPTION:
#   Tests for check-rabbitmq-consumers.rb
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
require_relative '../bin/check-rabbitmq-consumers.rb'

def consumer1
  {
    'name' => 'example-queue1',
    'consumers' => 6
  }
end

def consumer2
  {
    'name' => 'example-queue2',
    'consumers' => 1
  }
end

def consumer3
  {
    'name' => 'example3',
    'consumers' => 4
  }
end

def consumer4
  {
    'name' => 'example-queue4',
    'consumers' => 1
  }
end

def consumer5
  {
    'name' => 'example5',
    'consumers' => 1
  }
end

def consumer6
  {
    'name' => 'test-queue6',
    'consumers' => 1
  }
end

def consumer7
  {
    'name' => 'example-queue7',
    'consumers' => 0
  }
end

def consumer8
  {
    'name' => 'example-queue8',
    'consumers' => 3
  }
end

class RabbitInfoStub
end

describe CheckRabbitMQConsumers, 'run' do
  it 'Threshold `ok` when the consumer is above the default threshold of 5' do
    check = CheckRabbitMQConsumers.new ['--queue', 'example-queue1']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [consumer1]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:critical)
    expect(check).not_to receive(:warning)
    expect(check).to receive(:ok)

    check.run
  end

  it 'Threshold `critical` when the consumer is below the default threshold of 2' do
    check = CheckRabbitMQConsumers.new []
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [consumer2]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues in critical state: example-queue2:1-Consumers. ')

    check.run
  end

  it 'Threshold `warning` when the consumer is below the default threshold of 5' do
    check = CheckRabbitMQConsumers.new []
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [consumer3]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:warning).with('Queues in warning state: example3:4-Consumers')

    check.run
  end

  it 'Threshold `critical` when the consumer is below the custom threshold of 0' do
    check = CheckRabbitMQConsumers.new ['-c', '0']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [consumer7]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues in critical state: example-queue7:0-Consumers. ')

    check.run
  end

  it 'Threshold `warning` when the consumer is below the custom threshold of 3' do
    check = CheckRabbitMQConsumers.new ['-w', '3']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [consumer8]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:warning).with('Queues in warning state: example-queue8:3-Consumers')

    check.run
  end

  it 'Combined Threshold when the consumer is below the custom threshold of 3' do
    check = CheckRabbitMQConsumers.new ['-c', '1', '-w', '3', '--queue', 'example*', '--exclude', 'example-queue2|test*', '--regex']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [consumer1, consumer2, consumer3, consumer4, consumer5, consumer6, consumer7, consumer8]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues in critical state: example-queue4:1-Consumers, example5:1-Consumers, example-queue7:0-Consumers. ')

    check.run
  end

  it 'Regex should return all queues starting with example' do
    check = CheckRabbitMQConsumers.new ['--regex', '--queue', 'example*']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [consumer2, consumer4, consumer5, consumer6]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues in critical state: example-queue2:1-Consumers, example-queue4:1-Consumers, example5:1-Consumers. ')

    check.run
  end

  it 'Regex with exclude. Only example-queue2 and example-queue4 should be checked example5 and test-queue6 should be ignored' do
    check = CheckRabbitMQConsumers.new ['--regex', '--queue', 'example*', '--exclude', 'example5']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [consumer2, consumer4, consumer5, consumer6]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues in critical state: example-queue2:1-Consumers, example-queue4:1-Consumers. ')

    check.run
  end

  it 'Multi regex & exclude. Only example-queue4, example5 and test-queue6 should be checked example-queue2 should be ignored' do
    check = CheckRabbitMQConsumers.new ['--regex', '--queue', 'example*|test*', '--exclude', 'example-queue2']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [consumer2, consumer4, consumer5, consumer6]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues in critical state: example-queue4:1-Consumers, example5:1-Consumers, test-queue6:1-Consumers. ')

    check.run
  end

  it 'Exclude only. Only example-queue2, example-queue4 and example5 should be checked. test-queue6 should be ignored' do
    check = CheckRabbitMQConsumers.new ['--exclude', 'test-queue6']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [consumer2, consumer4, consumer5, consumer6]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues in critical state: example-queue2:1-Consumers, example-queue4:1-Consumers, example5:1-Consumers. ')

    check.run
  end

  it 'Multi queue. A combination of queues with one missing' do
    check = CheckRabbitMQConsumers.new ['--queue', 'nonexistant,example-queue1,example-queue2,test-queue6']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [consumer1, consumer2, consumer3, consumer4, consumer6]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with("Queues in critical state: example-queue2:1-Consumers, test-queue6:1-Consumers. \nQueues missing: nonexistant")

    check.run
  end

  it 'Unknown queue. The specified queue does not exist should return a critical' do
    check = CheckRabbitMQConsumers.new ['--queue', 'nonexistant']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [consumer1, consumer2, consumer3, consumer4]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues missing: nonexistant')

    check.run
  end

  it 'No queues recieved from rabbitmq api should return critical' do
    check = CheckRabbitMQConsumers.new
    expect { check.run }.to raise_error(SystemExit)
      .and output("CheckRabbitMQConsumers CRITICAL: Could not find any queue, check rabbitmq server\n")
      .to_stdout
  end
end
