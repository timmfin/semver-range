$:.push File.expand_path("../lib", __FILE__)
require 'semver'
require 'semver_range'

Gem::Specification.new do |spec|
  spec.name = "semver_range"
  spec.version = SemVer.find.format '%M.%m.%p'
  spec.summary = "Semantic Versioning Ranges"
  spec.description = "Extends haf/semver (as defined at http://semver.org) to have query-able ranges"
  spec.email = "timmfin@timmfin.net"
  spec.authors = ["Tim Finley"]
  spec.homepage = 'https://github.com/timmfin/semver_range'
  spec.files = [".semver", "semver_range.gemspec", "README.md"] + Dir["lib/**/*.rb"]
  spec.add_runtime_dependency 'semver', '~>3.3.3'
  spec.add_development_dependency 'rspec', '~>2.12.0'
  spec.has_rdoc = true
end
