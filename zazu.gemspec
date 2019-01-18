require_relative 'lib/zazu'

Gem::Specification.new {|s|
  s.name = 'zazu'
  s.version = Zazu::VERSION
  s.licenses = ['MIT']
  s.summary = 'Fetch tools and run them'
  s.description = 'A configurable build component that can download a tool from a URL if necessary, then run it.'
  s.homepage = 'https://github.com/ryancalhoun/zazu'
  s.authors = ['Ryan Calhoun']
  s.email = ['ryanjamescalhoun@gmail.com']
  
  s.files = Dir["{lib}/**/*"] + %w(LICENSE README.md)

  s.add_runtime_dependency 'colorize', '~> 0'
}
