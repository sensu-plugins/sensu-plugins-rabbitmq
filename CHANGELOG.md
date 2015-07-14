#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## Unreleased][unreleased]

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
