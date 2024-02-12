# frozen_string_literal: true

require_relative "lib/goodmoggoodnews/version"

Gem::Specification.new do |spec|
  spec.name          = "goodmoggoodnews"
  spec.version       = Goodmoggoodnews::VERSION
  spec.authors       = ["Koichiro IWAO"]
  spec.email         = ["meta@vmeta.jp"]

  spec.summary       = "もぐもぐアラート"
  spec.description   = "the pillowsファンクラブのブログ更新をお知らせします "
  spec.homepage      = "https://github.com/metalefty/goodmoggoodnews"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/metalefty/goodmoggoodnews"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "twitter", "~> 7.0.0"
  spec.add_dependency "x", "~>0.14.0"
  spec.add_dependency "nokogiri", "~> 1.11.1"
  spec.add_dependency "faraday", "~> 1.3.0"
  spec.add_dependency "faraday_middleware", "~> 1.0.0"
  spec.add_dependency "activesupport", "~> 6.1.1"
  spec.add_dependency "line-bot-api", "~> 1.2"
  spec.add_dependency "redis", "~> 5.0.1"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
