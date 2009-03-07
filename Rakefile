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
$:.push File.join(File.dirname(__FILE__), 'lib')
require 'syrup'

version = Syrup::Application.version
name = "syrup"

spec = Gem::Specification.new do |s|
	s.name = name
	s.version = version
	s.summary = "Ruby service application manager."
	s.description = "Syrup is a process manager for working with services. It provides the ability to deploy and manage long-running services."
	s.author = "Paul Jones"
	s.email = "pauljones23@gmail.com"
	s.homepage = "http://github.com/vuderacha/syrup/"
	s.executables = [ "syrup" ]
	s.default_executable = "syrup"
	#s.rubyforge_project = "syrup"

	s.platform = Gem::Platform::RUBY
	s.has_rdoc = true
	
	s.files = %w(Rakefile) + Dir.glob("{bin,lib,spec}/**/*")
	
	s.require_path = "lib"
	s.bindir = "bin"

	#s.add_dependency('rest-client', '>=0.8.2')
	#s.add_dependency('launchy', '>=0.3.2')
end

Rake::GemPackageTask.new(spec) do |p|
	p.need_tar = true if RUBY_PLATFORM !~ /mswin/
end

desc "Updates the Gemspec for Syrup"
task "syrup.gemspec" do |t|
  require 'yaml'
  open(t.name, "w") { |f| f.puts spec.to_yaml }
end

task :install => [ :test, :package ] do
	sh %{sudo gem install pkg/#{name}-#{version}.gem}
end

task :uninstall => [ :clean ] do
	sh %{sudo gem uninstall #{name}}
end

task :test => [ :spec ]

Rake::RDocTask.new do |t|
	t.rdoc_dir = 'rdoc'
	t.title    = "Syrup -- Process Manager"
	t.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object'
	t.options << '--charset' << 'utf-8'
	t.rdoc_files.include('README')
	t.rdoc_files.include('lib/syrup/*.rb')
end

CLEAN.include [ 'build/*', '**/*.o', '**/*.so', '**/*.a', 'lib/*-*', '**/*.log', 'pkg', 'lib/*.bundle', '*.gem', '.config' ]

