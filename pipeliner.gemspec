spec = Gem::Specification.new do |s|
    s.name              = 'pipeliner'
    s.author            = 'spox'
    s.email             = 'spox@modspox.com'
    s.version           = '1.1'
    s.summary           = 'Object Pipeline'
    s.platform          = Gem::Platform::RUBY
    s.files             = Dir['**/*']
    s.rdoc_options      = %w(--title pipeliner --main README.rdoc --line-numbers)
    s.extra_rdoc_files  = %w(README.rdoc CHANGELOG)
    s.require_paths     = %w(lib)
    s.required_ruby_version = '>= 1.8.6'
    s.add_dependency 'actionpool', '~> 0.2.3'
    s.add_dependency 'splib', '~> 1.4.3'
    s.homepage          = %q(http://github.com/spox/pipeliner)
    s.description       = "Simple library to allow pipeline styled communications between objects"
end
