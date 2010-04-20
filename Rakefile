# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'spec/rake/spectask'

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

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |rdoc|
  files =['README', 'LICENSE', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "pipeliner Docs"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.libs << Dir["lib"]
end