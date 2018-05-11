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

def utilisation1
  {
    'name' => 'example-queue1',
    'consumer_utilisation' => 1
  }
end

def utilisation2
  {
    'name' => 'example-queue2',
    'consumer_utilisation' => 0.23211730652213466
  }
end

def utilisation3
  {
    'name' => 'example3',
    'consumer_utilisation' => 0.772899906538027
  }
end

def utilisation4
  {
    'name' => 'example-queue4',
    'consumer_utilisation' => 0.23211730652213466
  }
end

def utilisation5
  {
    'name' => 'example5',
    'consumer_utilisation' => 0.23211730652213466
  }
end

def utilisation6
  {
    'name' => 'test-queue6',
    'consumer_utilisation' => 0.23211730652213466
  }
end

def utilisation7
  {
    'name' => 'example-queue7',
    'consumer_utilisation' => 0.1342116
  }
end

def utilisation8
  {
    'name' => 'example-queue8',
    'consumer_utilisation' => 0.6656453564322
  }
end

class RabbitInfoStub
end

describe CheckRabbitMQConsumerUtilisation, 'run' do
  it 'Threshold `ok` when the utilisation is above the default threshold of 0.9' do
    check = CheckRabbitMQConsumerUtilisation.new ['--queue', 'example-queue1']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [utilisation1]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:critical)
    expect(check).not_to receive(:warning)
    expect(check).to receive(:ok)

    check.run
  end

  it 'Threshold `critical` when the utilisation is below the default threshold of 0.5' do
    check = CheckRabbitMQConsumerUtilisation.new []
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [utilisation2]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues in critical state: example-queue2:23.0%. ')

    check.run
  end

  it 'Threshold `warning` when the utilisation is below the default threshold of 0.9' do
    check = CheckRabbitMQConsumerUtilisation.new []
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [utilisation3]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:warning).with('Queues in warning state: example3:77.0%')

    check.run
  end

  it 'Threshold `critical` when the utilisation is below the custom threshold of 0.2' do
    check = CheckRabbitMQConsumerUtilisation.new ['-c', '0.2']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [utilisation7]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues in critical state: example-queue7:13.0%. ')

    check.run
  end

  it 'Threshold `warning` when the utilisation is below the custom threshold of 0.7' do
    check = CheckRabbitMQConsumerUtilisation.new ['-w', '0.7']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [utilisation8]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:warning).with('Queues in warning state: example-queue8:67.0%')

    check.run
  end

  it 'Combined Threshold when the utilisation is below the custom threshold of 0.7' do
    check = CheckRabbitMQConsumerUtilisation.new ['-c', '0.6', '-w', '0.7', '--queue', 'example*', '--exclude', 'example-queue2|test*', '--regex']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [utilisation1, utilisation2,
                                                             utilisation3, utilisation4,
                                                             utilisation5, utilisation6,
                                                             utilisation7, utilisation8]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues in critical state: example-queue4:23.0%, example5:23.0%, example-queue7:13.0%. ')

    check.run
  end

  it 'Regex should return all queues starting with example' do
    check = CheckRabbitMQConsumerUtilisation.new ['--regex', '--queue', 'example*']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [utilisation2, utilisation4, utilisation5, utilisation6]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues in critical state: example-queue2:23.0%, example-queue4:23.0%, example5:23.0%. ')

    check.run
  end

  it 'Regex with exclude. Only example-queue2 and example-queue4 should be checked example5 and test-queue6 should be ignored' do
    check = CheckRabbitMQConsumerUtilisation.new ['--regex', '--queue', 'example*', '--exclude', 'example5']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [utilisation2, utilisation4, utilisation5, utilisation6]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues in critical state: example-queue2:23.0%, example-queue4:23.0%. ')

    check.run
  end

  it 'Multi regex & exclude. Only example-queue4, example5 and test-queue6 should be checked example-queue2 should be ignored' do
    check = CheckRabbitMQConsumerUtilisation.new ['--regex', '--queue', 'example*|test*', '--exclude', 'example-queue2']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [utilisation2, utilisation4, utilisation5, utilisation6]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues in critical state: example-queue4:23.0%, example5:23.0%, test-queue6:23.0%. ')

    check.run
  end

  it 'Exclude only. Only example-queue2, example-queue4 and example5 should be checked. test-queue6 should be ignored' do
    check = CheckRabbitMQConsumerUtilisation.new ['--exclude', 'test-queue6']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [utilisation2, utilisation4, utilisation5, utilisation6]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues in critical state: example-queue2:23.0%, example-queue4:23.0%, example5:23.0%. ')

    check.run
  end

  it 'Multi queue. A combination of queues with one missing' do
    check = CheckRabbitMQConsumerUtilisation.new ['--queue', 'nonexistant,example-queue1,example-queue2,test-queue6']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [utilisation1, utilisation2, utilisation3, utilisation4, utilisation6]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with("Queues in critical state: example-queue2:23.0%, test-queue6:23.0%. \nQueues missing: nonexistant")

    check.run
  end

  it 'Unknown queue. The specified queue does not exist should return a critical' do
    check = CheckRabbitMQConsumerUtilisation.new ['--queue', 'nonexistant']
    info_stub = RabbitInfoStub.new
    allow(info_stub).to receive(:method_missing).and_return [utilisation1, utilisation2, utilisation3, utilisation4]
    allow(check).to receive(:acquire_rabbitmq_info).and_return info_stub

    expect(check).not_to receive(:ok)
    expect(check).to receive(:critical).with('Queues missing: nonexistant')

    check.run
  end

  it 'No queues recieved from rabbitmq api should return critical' do
    check = CheckRabbitMQConsumerUtilisation.new
    expect { check.run }.to raise_error(SystemExit)
      .and output("CheckRabbitMQConsumerUtilisation CRITICAL: Could not find any queue, check rabbitmq server\n")
      .to_stdout
  end
end
