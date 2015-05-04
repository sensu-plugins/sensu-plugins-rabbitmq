#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## Unreleased][unreleased]
* Add the ability to monitor all queues in the consumer count plugin
* Add ability to exclude specific queues in the consumer count plugin
* Added Ruby 2.2.0 to Travis
* Fixed the critical and warning values to alert when <= not < in check-rabbitmq-consumers.rb
* Added the ability to monitor message count per queue and exclude specific queues in check-rabbitmq-messages.rb
* Updated Rubocop to 0.30 and resolved all warnings
* Added additional node health checks to the check-rabbitmq-node-health.rb plugin
* Added development tasks to the Rakefile
* Remove copy paste errors in the Readme
* Added a Gemfile
* Improved the Vagrantfile
* Added egress rate to the metrics-rabbitmq-queue.rb plugin
* Updated the headers to match and use the new template for additional information
* Updated class names to match plugin names for better alert messaging
* Added encoding comment to each plugin
* Made all plugins executable
* Added check-rabbitmq-queue-drain-time.rb plugin
* Added queue drain time and the number of consumers to the metrics-rabbitmq-queue.rb plugin
* Added check-rabbitmq-network-partitions plugin
* Removed Rubygems require Ruby 1.8.7 backwards compatibility from all plugins

#### 0.0.1.alpha.1
*Intial sync from the sensu-community-plugins repository
