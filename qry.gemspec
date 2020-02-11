lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'qry/version'

Gem::Specification.new do |spec|
  spec.name = 'qry'
  spec.version = Qry::VERSION
  spec.authors = ['Austin Schneider']
  spec.email = ['me@austinschneider.com']

  spec.summary = 'Qry'
  spec.description = 'https://github.com/austinthecoder/qry'

  # spec.metadata['allowed_push_host'] = 'TODO: Set to 'http://mygemserver.com''

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rspec', '~> 3.9'
  spec.add_development_dependency 'sqlite3', '~> 1.3'

  spec.add_dependency 'icy', '~> 0.3'
  spec.add_dependency 'ivo', '~> 0.4'
  spec.add_dependency 'sequel', '~> 5.20'
end
