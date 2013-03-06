# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Marvin Frick"]
  gem.email         = ["frick@informatik.uni-luebeck.de"]
  gem.description   = %q{Ruby gem to connect to a websocket server}
  gem.summary       = %q{Allows you to connect to a websocket server-side, using the RFC 6455 protocol version. Sending and receiving data is supported. That's it.}
  gem.homepage      = "https://github.com/MrMarvin/simpleblockingwebsocketclient"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "simpleblockingwebsocketclient"
  gem.require_paths = ["lib"]
  gem.version       = "0.43"
end
