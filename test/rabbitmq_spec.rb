#!/usr/bin/env ruby
# frozen_string_literal: false

#
# rabbitmq
#
# DESCRIPTION:
#   Tests for rabbitmq.rb
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
require_relative '../lib/sensu-plugins-rabbitmq/rabbitmq.rb'

def queue_test
  {
    'name' => 'example-queue1'
  }
end

class DummyClass
end

describe Sensu::Plugin::RabbitMQ do
  before(:each) do
    @options = {
      host: 'localhost',
      port: 55_672,
      username: 'guest',
      password: 'guest'
    }
    @dummy_class = DummyClass.new
    @dummy_class.extend(Sensu::Plugin::RabbitMQ::Common)
  end

  it 'Acquire Rabbitmq info gets rescued' do
    allow(@dummy_class).to receive(:warning)
  end

  it 'Acquire Rabbitmq info missing config' do
    allow(@dummy_class).to receive(:config).and_return(nil)
    allow(@dummy_class).to receive(:warning) do |arg|
      expect(arg).to eq('could not get rabbitmq info')
    end
  end

  it 'Queue List Builder nil should return an empty array' do
    allow(@dummy_class).to receive(:config).and_return('regex' => 'true')
    check = @dummy_class.queue_list_builder nil
    expect(check).to eq []
  end

  it 'Queue List Builder Regex should return a single array element' do
    allow(@dummy_class).to receive(:config).and_return('regex' => 'true')
    check = @dummy_class.queue_list_builder '.*'
    expect(check).to eq ['.*']
  end

  it 'Queue List Builder String should return a single array element' do
    allow(@dummy_class).to receive(:config).and_return('regex' => 'false')
    check = @dummy_class.queue_list_builder 'example-queue1'
    expect(check).to eq ['example-queue1']
  end

  it 'Queue List Builder String List should return array' do
    allow(@dummy_class).to receive(:config).and_return('regex' => 'false')
    check = @dummy_class.queue_list_builder 'example-queue1,example-queue2,example-queue3'
    expect(check).to eq ['example-queue1', 'example-queue2', 'example-queue3']
  end
end
