# frozen_string_literal: true

require_relative 'lib/infield/version'

Gem::Specification.new do |spec|
  spec.name = 'infield'
  spec.version = Infield::VERSION
  spec.authors = ['Infield']
  spec.email = ['support@infield.ai']

  spec.summary = 'Send deprecation warnings to Infield'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.0.0'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'rspec'
end
