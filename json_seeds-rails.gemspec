$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "json_seeds/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  # rubocop:disable Layout/ExtraSpacing
  spec.name        = "json_seeds-rails"
  spec.summary     = "JSON Seeds for rails/active_record."
  spec.description = "JSON Seeds for rails/active_record."
  spec.authors     = ["BeeGood IT"]
  spec.email       = ["info@beegoodit.de"]
  spec.version     = JsonSeeds::VERSION
  # rubocop:enable Layout/ExtraSpacing

  spec.files = Dir["{app,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "activerecord"
  spec.add_dependency "rao-service"

  spec.add_development_dependency "bootsnap"
  spec.add_development_dependency "guard-bundler"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-standardrb"
  spec.add_development_dependency "pry-rails"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "standardrb"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "sprockets-rails"
end
