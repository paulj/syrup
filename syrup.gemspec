--- !ruby/object:Gem::Specification 
name: syrup
version: !ruby/object:Gem::Version 
  version: 0.0.1
platform: ruby
authors: 
- Paul Jones
autorequire: 
bindir: bin
cert_chain: []

date: 2009-03-07 00:00:00 +00:00
default_executable: syrup
dependencies: []

description: Syrup is a process manager for working with services. It provides the ability to deploy and manage long-running services.
email: pauljones23@gmail.com
executables: 
- syrup
extensions: []

extra_rdoc_files: []

files: 
- Rakefile
- bin/syrup
- lib/a
- lib/a/activated
- lib/activated
- lib/loader.rb
- lib/syrup
- lib/syrup/daemon.rb
- lib/syrup/manager.rb
- lib/syrup.rb
- lib/test.rb
- lib/test2.rb
- lib/tmp
- lib/tmp/config.ru
- lib/tmp/config.sy
- lib/tmp/test_app.rb
- spec/syrup_spec.rb
has_rdoc: true
homepage: http://github.com/vuderacha/syrup/
post_install_message: 
rdoc_options: []

require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
required_rubygems_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
requirements: []

rubyforge_project: 
rubygems_version: 1.3.1
signing_key: 
specification_version: 2
summary: Ruby service application manager.
test_files: []

