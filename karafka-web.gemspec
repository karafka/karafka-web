# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'karafka/web/version'

Gem::Specification.new do |spec|
  spec.name        = 'karafka-web'
  spec.version     = ::Karafka::Web::VERSION
  spec.platform    = Gem::Platform::RUBY
  spec.authors     = ['Maciej Mensfeld']
  spec.email       = %w[contact@karafka.io]
  spec.homepage    = 'https://karafka.io'
  spec.summary     = 'Karafka ecosystem Web UI interface'
  spec.description = 'Karafka ecosystem plug-and-play Web UI'
  spec.licenses    = %w[LGPL-3.0 Commercial]

  spec.add_dependency 'erubi', '~> 1.4'
  spec.add_dependency 'karafka', '>= 2.1.8', '< 3.0.0'
  spec.add_dependency 'karafka-core', '>= 2.0.13', '< 3.0.0'
  spec.add_dependency 'roda', '~> 3.68', '>= 3.69'
  spec.add_dependency 'tilt', '~> 2.0'

  spec.add_development_dependency 'rackup', '~> 0.2'

  if $PROGRAM_NAME.end_with?('gem')
    spec.signing_key = File.expand_path('~/.ssh/gem-private_key.pem')
  end

  spec.cert_chain    = %w[certs/cert_chain.pem]
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  spec.executables   = %w[karafka-web]
  spec.require_paths = %w[lib]

  spec.metadata = {
    'funding_uri' => 'https://karafka.io/#become-pro',
    'homepage_uri' => 'https://karafka.io',
    'changelog_uri' => 'https://github.com/karafka/karafka-web/blob/master/CHANGELOG.md',
    'bug_tracker_uri' => 'https://github.com/karafka/karafka-web/issues',
    'source_code_uri' => 'https://github.com/karafka/karafka-web',
    'documentation_uri' => 'https://karafka.io/docs',
    'rubygems_mfa_required' => 'true'
  }
end
