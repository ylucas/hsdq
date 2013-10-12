# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hsdq/version'

Gem::Specification.new do |spec|
  spec.name          = "hsdq"
  spec.version       = Hsdq::VERSION
  spec.authors       = ["Yves Lucas"]
  spec.email         = ["ylucas@ylucas.com"]

  spec.summary       = %q{Hsdq, High Speed Distributed Queue for message bus.}
  spec.description   = %q{Hsdq: Light weight and distributed, Hsdq allow distributed applications to exchange requests and data at high speed, work in parallel and scale horizontaly.}
  # spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "GPLV3"

  # spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # spec.bindir        = "exe"
  # spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  # end

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10"
  spec.add_development_dependency "redis", "~> 3.0"
  spec.add_development_dependency "json", "~> 1.8"
end
