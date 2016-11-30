$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "metatags/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "Hakuna Metatags"
  s.version     = Metatags::VERSION
  s.authors     = ["niuage"]
  s.email       = ["niuage@gmail.com"]
  s.homepage    = "https://devpost.com"
  s.summary     = "Makes it easier to add meta tags to Devpost pages."
  s.description = "Provides a default way to build meta tags, and allows users to extend it."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2"

  s.add_development_dependency "sqlite3"
end
