[![Sensu Bonsai Asset](https://img.shields.io/badge/Bonsai-Download%20Me-brightgreen.svg?colorB=89C967&logo=sensu)](https://bonsai.sensu.io/assets/sensu-plugins/sensu-plugins-rabbitmq)
[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-rabbitmq.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-rabbitmq)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-rabbitmq.svg)](http://badge.fury.io/rb/sensu-plugins-rabbitmq)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-rabbitmq/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-rabbitmq)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-rabbitmq/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-rabbitmq)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-rabbitmq.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-rabbitmq)

## Sensu Plugins RabbitMQ Plugin

- [Overview](#overview)
- [Files](#files)
- [Usage examples](#usage-examples)
- [Configuration](#configuration)
  - [Sensu Go](#sensu-go)
    - [Asset registration](#asset-registration)
    - [Asset definition](#asset-definition)
    - [Check definition](#check-definition)
  - [Sensu Core](#sensu-core)
    - [Check definition](#check-definition)
- [Installation from source](#installation-from-source)
- [Additional notes](#additional-notes)
- [Contributing](#contributing)

### Overview

This plugin provides native RabbitMQ instrumentation for monitoring and metrics collection, including service health, message, consumer, and queue health/metrics via `rabbitmq_management`, and more.

### Files
 * bin/check-rabbitmq-alive.rb
 * bin/check-rabbitmq-amqp-alive.rb
 * bin/check-rabbitmq-cluster-health.rb
 * bin/check-rabbitmq-consumers.rb
 * bin/check-rabbitmq-consumer-utilisation.rb
 * bin/check-rabbitmq-messages.rb
 * bin/check-rabbitmq-network-partitions.rb
 * bin/check-rabbitmq-node-health.rb
 * bin/check-rabbitmq-node-usage.rb
 * bin/check-rabbitmq-queue-drain-time.rb
 * bin/check-rabbitmq-queue.rb
 * bin/check-rabbitmq-queues-synchronised.rb
 * bin/check-rabbitmq-stomp-alive.rb
 * bin/metrics-rabbitmq-overview.rb
 * bin/metrics-rabbitmq-queue.rb
 * bin/metrics-rabbitmq-exchange.rb
 
**check-rabbitmq-alive**
Checks if RabbitMQ server is alive using the REST API.

**check-rabbitmq-amqp-alive**
Checks if RabbitMQ server is alive using AMQP.

**check-rabbitmq-cluster-health**
Checks if RabbitMQ server's cluster nodes are in a running state. Also accepts an optional list of nodes and verifies that those nodes are present in the cluster.

**check-rabbitmq-consumers**
Checks the number of consumers on the RabbitMQ server.

**check-rabbitmq-consumer-utilisation**
Checks the consumer utilisation percentage (the fraction of time in which the queue is able to immediately deliver messages to consumer). If this number drops in percentage this may result in slower message delivery and indicate issues with the queue.

**check-rabbitmq-messages**
Checks the total number of messages queued on the RabbitMQ server. 

**check-rabbitmq-network-partitions**
Checks if a [RabbitMQ network partition](https://www.rabbitmq.com/partitions.html) has occured.

**check-rabbitmq-node-health**
Checks if RabbitMQ server node is in a running state.

**check-rabbitmq-node-usage**
Checks and shows usage for RabbitMQ server node.

**check-rabbitmq-queue-drain-time**
Checks the time it will take for each queue on the RabbitMQ server to drain based on the current message egress rate.  For example, if a queue has 1,000 messages in it but egresses only 1 message per second, the alert would fire because this is greater than the default critical level of 360 seconds.

**check-rabbitmq-queue**
Checks the number of messages queued on the RabbitMQ server in a specific queues.

**check-rabbitmq-queues-synchronised**
Checks that all mirrored queues that have slaves are synchronised.

**check-rabbitmq-stomp-alive**
Checks if RabbitMQ server is alive and responding to STOMP requests.

**metrics-rabbitmq-overview**
Shows RabbitMQ 'overview' stats similar to those shown on the main page of the rabbitmq_management web UI. 

**metrics-rabbitmq-queue**
Gathers the following per-queue rabbitmq metrics: message count, average egress rate, "drain time" metric (the time a queue will take to reach 0 based on the egress rate), and consumer count.

**metrics-rabbitmq-exchange**
Gathers all the available exchange metrics.

## Usage examples

### Help

**check-rabbitmq-alive**
```
Usage: check-rabbitmq-alive.rb (options)
    -w, --host HOST                  RabbitMQ host
    -i, --ini VALUE                  Configuration ini file
    -p, --password PASSWORD          RabbitMQ password
    -P, --port PORT                  RabbitMQ API port
        --ssl                        Enable SSL for connection to RabbitMQ
    -u, --username USERNAME          RabbitMQ username
        --verify_ssl_off             Do not check validity of SSL cert. Use for self-signed certs, etc (insecure)
    -v, --vhost VHOST                RabbitMQ vhost
```

**metrics-rabbitmq-overview**
```
Usage: metrics-rabbitmq-overview.rb (options)
        --host HOST                  RabbitMQ management API host
    -i, --ini VALUE                  Configuration ini file
        --password PASSWORD          RabbitMQ management API password
        --port PORT                  RabbitMQ management API port
        --scheme SCHEME              Metric naming scheme, text to prepend to $queue_name.$metric
        --ssl                        Enable SSL for connection to the API
        --username USER              RabbitMQ management API user
```

## Configuration
### Sensu Go
#### Asset registration

Assets are the best way to make use of this plugin. If you're not using an asset, please consider doing so! If you're using sensuctl 5.13 or later, you can use the following command to add the asset: 

`sensuctl asset add sensu-plugins/sensu-plugins-rabbitmq`

If you're using an earlier version of sensuctl, you can download the asset definition from [this project's Bonsai asset index page](https://bonsai.sensu.io/assets/sensu-plugins/sensu-plugins-rabbitmq).

#### Asset definition

```yaml
---
type: Asset
api_version: core/v2
metadata:
  name: sensu-plugins-rabbitmq
spec:
  url: https://assets.bonsai.sensu.io/7d56607309127ff0a9f6b198b3014a4f35b99e2b/sensu-plugins-rabbitmq_8.0.0_centos_linux_amd64.tar.gz
  sha512: a0c33a5649199efc4926cc0125923df1678191a81bd7f833136016c98d32aa399b75ba8433e8551f93b6c56ec09a2af31207b22544e25f085f559ffbac352d45
```

#### Check definition

```yaml
---
type: CheckConfig
spec:
  command: "check-rabbitmq-alive.rb"
  handlers: []
  high_flap_threshold: 0
  interval: 10
  low_flap_threshold: 0
  publish: true
  runtime_assets:
  - sensu-plugins/sensu-plugins-rabbitmq
  - sensu/sensu-ruby-runtime
  subscriptions:
  - linux
```

### Sensu Core

#### Check definition
```json
{
  "checks": {
    "check-rabbitmq": {
      "command": "check-rabbitmq-alive.rb",
      "subscribers": ["linux"],
      "interval": 10,
      "refresh": 10,
      "handlers": ["influxdb"]
    }
  }
}
```

## Installation from source

### Sensu Go

See the instructions above for [asset registration](#asset-registration).

### Sensu Core

Install and setup plugins on [Sensu Core](https://docs.sensu.io/sensu-core/latest/installation/installing-plugins/).

## Additional notes

### Sensu Go Ruby Runtime Assets

The Sensu assets packaged from this repository are built against the Sensu Ruby runtime environment. When using these assets as part of a Sensu Go resource (check, mutator, or handler), make sure to include the corresponding [Sensu Ruby Runtime Asset](https://bonsai.sensu.io/assets/sensu/sensu-ruby-runtime) in the list of assets needed by the resource.

### Permissions

To run these checks, you need to set the following permissions:

```
:conf => '^aliveness-test$',
:write => '^amq\.default$',
:read => '.*'
```

You must also add the `monitoring` tag:

```
rabbitmqctl add_user sensu_monitoring $MY_SUPER_LONG_SECURE_PASSWORD
rabbitmqctl set_permissions  -p / sensu_monitoring "^aliveness-test$" "^amq\.default$" "^(amq\.default|aliveness-test)$"
rabbitmqctl set_user_tags sensu_monitoring monitoring
```

**We recommended that you use minimum permissions and do not give administrator access.**

## Contributing

See [CONTRIBUTING.md](https://github.com/sensu-plugins/sensu-plugins-rabbitmq/blob/master/CONTRIBUTING.md) for information about contributing to this plugin.

