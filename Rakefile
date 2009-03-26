require 'rake'
require 'spec/rake/spectask'

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
	t.spec_opts  = ["-cfs"]
	t.spec_files = FileList['spec/**/*_spec.rb']
end

desc "Print specdocs"
Spec::Rake::SpecTask.new(:doc) do |t|
	t.spec_opts = ["--format", "specdoc", "--dry-run"]
	t.spec_files = FileList['spec/*_spec.rb']
end

desc "Generate RCov code coverage report"
Spec::Rake::SpecTask.new('rcov') do |t|
	t.spec_files = FileList['spec/*_spec.rb']
	t.rcov = true
	t.rcov_opts = ['--exclude', 'examples']
end

task :default => :spec

######################################################

require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'fileutils'
include FileUtils

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "syrup"
  	s.summary = "Ruby service application manager."
  	s.description = "Syrup is a process manager for working with services. It provides the ability to deploy and manage long-running services."
  	s.author = "Paul Jones"
  	s.email = "pauljones23@gmail.com"
  	s.homepage = "http://github.com/vuderacha/syrup/"
  	s.executables = [ "syrup" ]
  	s.default_executable = "syrup"
  	
  	s.files = %w(Rakefile README.rdoc VERSION.yml) + Dir.glob("{bin,lib,spec}/**/*")

  	s.require_path = "lib"
  	s.bindir = "bin"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

task :test => [ :spec ]

Rake::RDocTask.new do |t|
	t.rdoc_dir = 'rdoc'
	t.title    = "Syrup -- Process Manager"
	t.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object'
	t.options << '--charset' << 'utf-8'
	t.rdoc_files.include('README.rdoc')
	t.rdoc_files.include('lib/syrup/*.rb')
end

CLEAN.include [ 'build/*', '**/*.o', '**/*.so', '**/*.a', 'lib/*-*', '**/*.log', 'pkg', 'lib/*.bundle', '*.gem', '.config' ]

