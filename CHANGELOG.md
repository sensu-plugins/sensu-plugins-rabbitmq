#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]

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

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/1.3.0...HEAD
[1.3.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/1.2.0...1.3.0
[1.2.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/0.1.0...1.0.0
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/0.0.4...0.1.0
[0.0.4]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/0.0.1...0.0.3
[0.0.3]: https://github.com/sensu-plugins/sensu-plugins-rabbitmq/compare/0.0.1...0.0.3
