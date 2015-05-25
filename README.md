## Sensu-Plugins-rabbitmq

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-rabbitmq.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-rabbitmq)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-rabbitmq.svg)](http://badge.fury.io/rb/sensu-plugins-rabbitmq)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-rabbitmq/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-rabbitmq)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-rabbitmq/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-rabbitmq)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-rabbitmq.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-rabbitmq)

## Functionality

## Files
 * bin/check-rabbitmq-alive.rb
 * bin/check-rabbitmq-amqp-alive.rb
 * bin/check-rabbitmq-cluster-health.rb
 * bin/check-rabbitmq-consumers.rb
 * bin/check-rabbitmq-messages.rb
 * bin/check-rabbitmq-network-partitions.rb
 * bin/check-rabbitmq-node-health.rb
 * bin/check-rabbitmq-queue-drain-time.rb
 * bin/check-rabbitmq-queue.rb
 * bin/check-rabbitmq-stomp-alive.rb
 * bin/metrics-rabbitmq-overview.rb
 * bin/metrics-rabbitmq-queue.rb

## Usage

## Installation

Add the public key (if you haven’t already) as a trusted certificate

```
gem cert --add <(curl -Ls https://raw.githubusercontent.com/sensu-plugins/sensu-plugins.github.io/master/certs/sensu-plugins.pem)
gem install sensu-plugins-rabbitmq -P MediumSecurity
```

You can also download the key from /certs/ within each repository.

#### Rubygems

`gem install sensu-plugins-rabbitmq`

#### Bundler

Add *sensu-plugins-rabbitmq* to your Gemfile and run `bundle install` or `bundle update`

#### Chef

Using the Sensu **sensu_gem** LWRP
```
sensu_gem 'sensu-plugins-rabbitmq' do
  options('--prerelease')
  version '0.0.1.alpha.1'
end
```

Using the Chef **gem_package** resource
```
gem_package 'sensu-plugins-rabbitmq' do
  options('--prerelease')
  version '0.0.1.alpha.1'
end
```

## Notes
