# Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed [here](https://github.com/sensu-plugins/community/blob/master/HOW_WE_CHANGELOG.md)

## [Unreleased]
### Fixed
- metrics-rabbitmq-queue.rb: fix metrics collection under corrupted RabbitMQ cluster circumstances (@multani)

## [4.1.0] - 2018-03-31
### Added
- check-rabbitmq-queues-synchronised.rb: Allow skipping of ssl cert verification, similar to other checks (@mattdoller)

## [4.0.1] - 2018-03-27
### Security
- updated yard dependency to `~> 0.9.11` per: https://nvd.nist.gov/vuln/detail/CVE-2017-17042 (@majormoses)

## [4.0.0] - 2018-03-17
### Security
- updated rubocop dependency to `~> 0.51.0` per: https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-8418. (@majormoses)

### Breaking Changes
- removed ruby `< 2.1` support (@majormoses)

### Changed
- appeased the cops (@majormoses)

## [3.6.0] - 2017-10-04
### Added
- check-rabbitmq-queues-synchronised.rb: added new check if all mirrored queues are synchronised (@cyrilgdn)

### Changed
- updated CHANGELOG guidelines location (@majormoses)

## [3.5.0] - 2017-09-05
### Changed
- RabbitMQ module with common code (@rthouvenin)
- Check and Metrics base classes (@rthouvenin)

## [3.4.0] - 2017-08-20
### Added
- check-rabbitmq-amqp-alive.rb: Added threading and heartbeat interval options (@bdeo)

## [3.3.0] - 2017-08-20
### Added
- check-rabbitmq-consumers.rb: Added ability to select queues with regular expressions. (@jtduby)

### Added
 - ruby 2.4 support (@majormoses)

### Changed
 - metrics-rabbitmq-queue, metrics-rabbitmq-exchange, check-rabbitmq-queue: use the new base classes (@rthouvenin)
### Fixed
 - PR template spelling (@majormoses)

## [3.2.0] - 2017-06-20
### Added
 - metrics-rabbitmq-exchange: new metrics for exchange, working similarly to queue metrics (@rthouvenin)

## [3.1.1] - 2017-05-17
### Fixed
 - metrics-rabbitmq-queue.rb: Fix use of =~ operator

## [3.1.0] - 2017-05-16
### Added
 - metrics-rabbitmq-queue.rb: --metrics option to specifiy which metrics to gather (@rthouvenin)

## [3.0.0] - 2017-05-10
### Breaking change
 - Previously some checks used --user to specify username, now all scripts use --username

### Added
 - --ini option for all checks to specify username and password in a config file (@bootswithdefer)

## [2.3.0] - 2017-05-09
### Added
- check-rabbitmq-node-usage.rb: added new check to look at rmq node resource useage. (@DvaBearqLoza)

## [2.2.0] - 2017-05-08
### Added
 - check-rabbitmq-queue.rb: Added --below feature to specify if value below threshold should generate alert (@alexpekurovsky)

### Fixed
 - check-rabbitmq-queue.rb: Fixes for assigning values to critical or warning states (@alexpekurovsky)
 - check-rabbitmq-consumers.rb: Fixes rabbitmq empty value for consumers in some situations (@mdzidic)
 - check-rabbitmq-consumers.rb: Fixes rabbitmq plugin crash when node is in network partition (@mdzidic)

### Changed
- bump stomp version to 1.4.3

## [2.1.0] - 2017-01-10
### Added
 - check-rabbitmq-queue.rb: Added features for using regex in queue name and pretty output (@alexpekurovsky)

### Fixed
- check-rabbitmq-node-health: prevent fd check failing on OSX due to non-numeric fd_used (@thisisjaid)

## [2.0.0] - 2016-10-17
### Added
 - check-rabbitmq-queue-drain.rb: Added a default include-all value for the regex queue filter option

### Changed
- bump bunny version to 2.5.0
- bump amq-protocol version to 2.0.1
- drop ruby v1.9.3 support

### Added
- Add ruby 2.3.0 support

### Fixed
- check-rabbitmq-amqp-alive: properly close connection if connected

## [1.3.0] - 2016-04-13
### Added
- check-rabbitmq-cluster-health.rb: Added option to provide SSL CA certificate

### Changed
- set dep on sensu-plugin gem to be more relaxed

## [1.2.0] - 2016-04-13
### Added
- check-rabbitmq-amqp-alive.rb: Added support for TLS authentication
- metrics-rabbitmq-queue.rb: Added option to filter vhost with regular expression
- Added option to skip SSL cert checking

### Fixed
- check-rabbitmq-queue.rb: Fix default vhost
- check-rabbitmq-queue-drain-time.rb: Fix logging output and filter

### Changed
- Update to rubocop 0.37

## [1.1.0] - 2015-12-30
### Added
- check-rabbitmq-queue-drain-time.rb: Added option to filter vhost with regular expression

## [1.0.0] - 2015-12-01
### Fixed
- check-rabbitmq-node-health.rb: Fix messages for file descriptor alerts
- check-rabbitmq-node-health.rb: Make options unique

NOTE: this release changes the option flags in check-rabbitmq-node-health.rb to be unique.

## [0.1.0] - 2015-11-19
### Changed
- Upgrade to rubocop 0.32.1 and cleanup

### Added
- check-rabbitmq-queue.rb: Added option to ignore non-existent queues
- check-rabbitmq-queue.rb: Added vhost support
- Added SSL support to check-rabbitmq-cluster-health.rb and check-rabbitmq-node-health.rb

### Fixed
- metrics-rabbitmq-queue.rb: Fix error when queue['messages'] is missing

## [0.0.4] - 2015-08-18
### Changed
- pinned amq-protocol

## [0.0.3] - 2015-07-14
### Changed
- updated sensu-plugin gem to 1.2.0

## 0.0.1 - 2015-05-30
### Added
- Add the ability to monitor all queues in the consumer count plugin
- Add ability to exclude specific queues in the consumer count plugin
- Added Ruby 2.2.0 to Travis
- Added additional node health checks to the check-rabbitmq-node-health.rb plugin
- Added development tasks to the Rakefile
- Added a Gemfile
- Added egress rate to the metrics-rabbitmq-queue.rb plugin
- Added encoding comment to each plugin
- Added check-rabbitmq-queue-drain-time.rb plugin
- Added queue drain time and the number of consumers to the metrics-rabbitmq-queue.rb plugin
- Added check-rabbitmq-network-partitions plugin
- Added the ability to monitor message count per queue and exclude specific queues in check-rabbitmq-messages.rb

### Fixed
- Nil queue values should be treated as a 0 in the queue drain time plugin
- Fixed the critical and warning values to alert when <= not < in check-rabbitmq-consumers.rb

### Changed
- Updated Rubocop to 0.30 and resolved all warnings
- Updated the headers to match and use the new template for additional information
- Updated class names to match plugin names for better alert messaging
- Made all plugins executable

### Removed
- Remove copy paste errors in the Readme
- Removed Rubygems require Ruby 1.8.7 backwards compatibility from all plugins

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/4.1.0...HEAD
[4.1.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/4.0.1...4.1.0
[4.0.1]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/4.0.0...4.0.1
[4.0.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/3.6.0..4.0.0
[3.6.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/3.5.0...3.6.0
[3.5.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/3.4.0...3.5.0
[3.4.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/3.3.0...3.4.0
[3.3.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/3.2.0...3.3.0
[3.2.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/3.1.1...3.2.0
[3.1.1]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/3.1.0...3.1.1
[3.1.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/3.0.0...3.1.0
[3.0.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/2.3.0...3.0.0
[2.3.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/2.2.0...2.3.0
[2.2.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/2.1.0...2.2.0
[2.1.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/1.3.0...2.0.0
[1.3.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/1.2.0...1.3.0
[1.2.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/0.1.0...1.0.0
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/0.0.4...0.1.0
[0.0.4]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/0.0.1...0.0.3
[0.0.3]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/0.0.1...0.0.3
