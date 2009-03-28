# Very simple default fabric. Just execute the application!
Syrup::Runner.run_application



# Default Fabric that is included in all Syrup applications. If a new Fabric is being written, this
# file can be included to "inherit" the features it provides.

Syrup::Builder.instance.define do
  # Define a 'service' application type for running simple applications
  define_application_type :service do |name, app|
    in_fork(name) do
      load app
    end
  end

  # Executes a rack based application
  define_application_type :rack do |name, *args|
    # No default values in blocks, so do this "manually"
    command = args[0] || ''
  
    in_fork(name) do
      require 'rubygems'
      require 'rack'
      ARGV.replace(command.split(' '))
      load 'rackup'
    end
  end
end