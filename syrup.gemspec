# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{syrup}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Paul Jones"]
  s.date = %q{2009-03-26}
  s.default_executable = %q{syrup}
  s.description = %q{Syrup is a process manager for working with services. It provides the ability to deploy and manage long-running services.}
  s.email = %q{pauljones23@gmail.com}
  s.executables = ["syrup"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["Rakefile", "README.rdoc", "VERSION.yml", "bin/syrup", "lib/launcher.rb", "lib/syrup", "lib/syrup/daemon.rb", "lib/syrup/fabrics", "lib/syrup/fabrics/default.rb", "lib/syrup/manager.rb", "lib/syrup.rb", "spec/syrup_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/vuderacha/syrup/}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Ruby service application manager.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
