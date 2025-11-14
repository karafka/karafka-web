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
  spec.licenses    = %w[LGPL-3.0-only Commercial]

  spec.add_dependency 'erubi', '~> 1.4'
  spec.add_dependency 'karafka', '>= 2.5.2', '< 2.6.0'
  spec.add_dependency 'karafka-core', '>= 2.5.0', '< 2.6.0'
  spec.add_dependency 'roda', '~> 3.69', '>= 3.69'
  spec.add_dependency 'tilt', '~> 2.0'

  spec.add_development_dependency 'rackup', '~> 0.2'

  spec.required_ruby_version = '>= 3.2.0'

  spec.executables   = %w[karafka-web]
  spec.require_paths = %w[lib]

  spec.files = `git ls-files -z`
               .split("\x0")
               .reject { |f| f.match(%r{^(spec)/}) }
               .reject { |f| f.include?('.github')  }
               .reject { |f| f.start_with?('.')  }
               .reject { |f| f.end_with?('.map')  }

  spec.metadata = {
    'funding_uri' => 'https://karafka.io/#become-pro',
    'homepage_uri' => 'https://karafka.io',
    'changelog_uri' => 'https://karafka.io/docs/Changelog-Karafka-Web-UI',
    'bug_tracker_uri' => 'https://github.com/karafka/karafka-web/issues',
    'source_code_uri' => 'https://github.com/karafka/karafka-web',
    'documentation_uri' => 'https://karafka.io/docs',
    'rubygems_mfa_required' => 'true'
  }
end
