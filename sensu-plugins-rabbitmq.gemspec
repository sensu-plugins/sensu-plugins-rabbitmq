lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'date'

if RUBY_VERSION < '2.0.0'
  require 'sensu-plugins-rabbitmq'
else
  require_relative 'lib/sensu-plugins-rabbitmq'
end

Gem::Specification.new do |s|
  s.authors                = ['Sensu-Plugins and contributors']

  s.date                   = Date.today.to_s
  s.description            = 'This plugin provides native RabbitMQ instrumentation
                              for monitoring and metrics collection, including:
                              service health, message, consumer, and queue health/metrics
                              via `rabbitmq_management`, and more'
  s.email                  = '<sensu-users@googlegroups.com>'
  s.executables            = Dir.glob('bin/**/*.rb').map { |file| File.basename(file) }
  s.files                  = Dir.glob('{bin,lib}/**/*') + %w(LICENSE README.md CHANGELOG.md)
  s.homepage               = 'https://github.com/sensu-plugins/sensu-plugins-rabbitmq'
  s.license                = 'MIT'
  s.metadata               = { 'maintainer'         => '@mattyjones',
                               'development_status' => 'active',
                               'production_status'  => 'unstable - testing recommended',
                               'release_draft'      => 'false',
                               'release_prerelease' => 'false' }
  s.name                   = 'sensu-plugins-rabbitmq'
  s.platform               = Gem::Platform::RUBY
  s.post_install_message   = 'You can use the embedded Ruby by setting EMBEDDED_RUBY=true in /etc/default/sensu'
  s.require_paths          = ['lib']
  s.required_ruby_version  = '>= 1.9.3'

  s.summary                = 'Sensu plugins for rabbitmq'
  s.test_files             = s.files.grep(%r{^(test|spec|features)/})
  s.version                = SensuPluginsRabbitMQ::Version::VER_STRING

  s.add_runtime_dependency 'sensu-plugin',   '~> 1.2'
  s.add_runtime_dependency 'carrot-top',     '0.0.7'
  s.add_runtime_dependency 'stomp',          '1.3.4'
  s.add_runtime_dependency 'rest-client',    '1.8.0'
  s.add_runtime_dependency 'bunny',          '1.7.0'
  s.add_runtime_dependency 'amq-protocol',   '1.9.2' # locked as bunny 1.7.0 deps breaks on runby < 2

  s.add_development_dependency 'bundler',                   '~> 1.7'
  s.add_development_dependency 'codeclimate-test-reporter', '~> 0.4'
  s.add_development_dependency 'github-markup',             '~> 1.3'
  s.add_development_dependency 'pry',                       '~> 0.10'
  s.add_development_dependency 'rake',                      '~> 10.5'
  s.add_development_dependency 'redcarpet',                 '~> 3.2'
  s.add_development_dependency 'rubocop',                   '~> 0.40.0'
  s.add_development_dependency 'rspec',                     '~> 3.4'
  s.add_development_dependency 'yard',                      '~> 0.8'
end
