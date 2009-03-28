# Handler class for actually running an application
module Syrup
  class Runner
    # Initializes the runner with the given configuration store
    def initialize(config_store, logger)
      @config_store = config_store
      @logger = logger
    end
    
    # Runs the application
    def run(app_name)
      @logger.debug "Preparing to execute #{app_name}"
      app = @config_store.applications[app_name]
      
      # Gather the properties
      props = {}
        # {}.merge! won't work since the config_store properties aren't a real hash...
      @config_store.properties.each do |k,v| props[k] = v end
      app.properties.each do |k,v| props[k] = v end
      
      # Find the Fabric by going from app-specific to env-specific to default
      fabric = app.fabric
      fabric = @config_store.fabric if fabric.nil?
      fabric = default_fabric if fabric.nil?
      
      # Calculate the application executable
      @app_path = app.app
      
      # Activate all of the properties
      props.each do |k,v|
        @logger.debug "Applying constant #{k}=#{v}" if @verbose
        Kernel.const_set k, v
      end
      
      @@active_runner = self    # Record the active instance of this runner
      old_argv = ARGV.clone
      begin
        # Overwrite ARGV
        ARGV.replace(app.start_parameters)
        
        # Execute the fabric, which should internally perform a Syrup::Runner.run_application when it has prepared
        # adequately for the application to execute
        load fabric
      ensure
        ARGV.replace(old_argv)
        @@active_runner = nil
      end
    end
    
    def run_application
      raise "Cannot execute application outside of Fabric" if @app_path.nil?
      
      load @app_path
    end
    
    def self.run_application
      raise "Cannot execute application outside of Fabric" if @@active_runner.nil?
      
      active.run_application
    end
    
    def self.active
      @@active_runner
    end
    
    private
      def default_fabric
        File.join(File.dirname(__FILE__), 'fabrics', 'default.rb')
      end
  end
end