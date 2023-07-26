# frozen_string_literal: true

require_relative 'lib/construction_guard/version'

Gem::Specification.new do |spec|
  spec.name = 'construction_guard'
  spec.version = ConstructionGuard::VERSION
  spec.authors = ['Triplets']
  spec.email = ['']

  spec.summary = 'This gem provide security to unpublished website.'
  spec.description = 'This gem provide security to unpublished website.'
  spec.homepage = 'https://github.com/Sanish777/construction_guard'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.2'

  spec.metadata['allowed_push_host'] = 'https://github.com/Sanish777/construction_guard'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/Sanish777/construction_guard'
  spec.metadata['changelog_uri'] = 'https://github.com/Sanish777/construction_guard'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files += Dir["lib/**/*"]
  spec.add_dependency 'rails', '>= 5.0'
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency 'example-gem', '~> 1.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
