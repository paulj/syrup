require 'syrup/config_store'
require 'yaml'
require 'fileutils'

module Syrup
  # Manager for controlling the Syrup functionality
  class Manager
    def initialize(config_dir, logger, verbose)
      @config_dir = config_dir
      @logger = logger
      @verbose = verbose
      
      @config_store = Syrup::ConfigStore.new @config_dir
      @runner = Syrup::Runner.new @config_store, @logger
    end
    
    # Informs the manager to start all configured applications
    def start_all
      if @config_store.applications.length == 0
        @logger.warn 'No Applications activated yet. Nothing to do!'
        return true
      end
      
      @config_store.applications.each do |app_name, app|
        start(app_name)
      end
    end
    
    # Informs the manager to start the specified application
    def start(app_name)
      # Retrieve the details of the application to check that it is valid
      app = get_application(app_name, false)
      return false if app.nil?
      
      fork do
        Process.setsid
        exit if fork
        
        # Record our PID
        app.pid = Process.pid
        
        # Calculate the log filename for the application, and make sure the directory exists
        log_fn = File.join(File.dirname(app.app), 'log', "#{app_name}.log")
        FileUtils.mkdir_p File.dirname(log_fn)
        
        #Dir.chdir @working_dir
        File.umask 0000
        STDIN.reopen "/dev/null"
        STDOUT.reopen log_fn, "a"
        STDERR.reopen STDOUT
        trap("TERM") {exit}
        
        at_exit do
          # Release our pid
          app.pid = nil
        end
        
        # Run the application
        run_app(app_name)
      end
      
      return true
    end
    
    # Informs the manager to stop all configured applications
    def stop_all
      if @config_store.applications.length == 0
        @logger.warn 'No Applications activated yet. Nothing to do!'
        return true
      end
      
      stop(@config_store.applications.keys)
    end
    
    # Informs the manager to stop the named applications
    def stop(app_names)
      pids = []
      @config_store.applications.each do |app_name, app|
        pids << app.pid if app_names.include? app_name and not app.pid.nil? 
      end
      
      kill_pids pids
    end
    
    # Informs the manager to activate the given path
    def activate name, path, args
      # Retrieve ourselves an application object
      app = @config_store.applications[name]
      app = @config_store.create_application(name) if app.nil?
      
      # Store the path to the application
      app.app = File.expand_path(path)
      app.start_parameters = args
      
      true
    end
    
    # Informs the manager to run the given application in the foreground
    def run(names)
      # Create sub-processes for each of the named applications
      pids = []
      names.each do |name|
        pids << fork do
          run_app(name)
        end
      end
      
      # Register an at_exit handler to kill off all the pids
      at_exit do
        kill_pids pids
      end
      
      # Wait for all children to die
      Process.waitall.each do |pid, status|
        # We won't need to kill the processes that successfully exited
        pids.delete pid if status.exited?
      end
    end
    
    # Informs the manager to run the given application within the current process
    def run_app(name)
      @runner.run(name)
    end
    
    # Requests that the manager store the given variables as persistent configuration for the given application.
    def set_app_properties(app_name, properties)
      app = @config_store.applications[app_name]
      if app.nil?
        @logger.error "Unknown Application. Cannot set properties."
        return false
      end
      
      props.each do |pair|
        k,v = pair.split('=')
        if k.nil? or v.nil?
          @logger.error "Invalid set command. #{pair} not in the form K=V"
          return false
        end
        
        app.properties[k] = v
      end
    end
    
    # Requests that the manager store the given variables as persistent configuration that will be
    # restored when all applications are started
    def set_global_properties(props)
      props.each do |pair|
        k,v = pair.split('=')
        if k.nil? or v.nil?
          @logger.error "Invalid set command. #{pair} not in the form K=V"
          return false
        end
        
        @config_store.properties[k] = v
      end
    end
        
    # Requests that the manager remove the given keys from the stored properties for the given app.
    def unset_app_properties(app_name, props)
      app = @config_store.applications[app_name]
      if app.nil?
        @logger.error "Unknown Application. Cannot unset properties."
        return false
      end
      
      props.each do |prop|
        app.properties.delete prop
      end
    end
    
    # Requests that the manager remove the given keys from the stored properties
    def unset_global_properties(props)
      props.each do |prop|
        @config_store.properties.delete prop
      end
    end
        
    # Removes all stored properties for the current profile
    def clear_app_properties
      app = @config_store.applications[app_name]
      return true if app.nil?
      
      app.properties.clear
    end
    
    # Removes all stored properties for the current profile
    def clear_global_properties
      @config_store.properties.clear
    end

    # Requests that the manager load the given fabric for applications within the current profile
    def weave_global(fabric)
      @config_store.fabric = fabric
    end
    
    def unweave_global
      @config_store.fabric = nil
    end
    
    def weave_for_application(app_name, fabric)
      app = get_application(app_name, false)
      return false if app.nil?
      
      app.fabric = fabric
    end
    
    def unweave_for_application(app_name)
      app = get_application(app_name, false)
      return false if app.nil?
      
      app.fabric = nil
    end
    
    private
      def get_application(app_name, create_if_missing)
        app = @config_store.applications[app_name]
        app = @config_store.create_application(app_name) if create_if_missing and app.nil?
        
        if app.nil?
          @logger.error "Unknown Application #{app_name}"
        end
        
        app
      end
      
      def kill_pids(pids)
        # List of pids waiting at each round
        waiting_pids = []
        
        (1..5).each do
          waiting_pids = []
          pids.each do |pid|
            pid && Process.kill("TERM", pid) && waiting_pids << pid rescue puts "WARNING: Failed to kill #{pid}"
          end
        
          # Wait for the process to die
          (1..20).each do
            waiting_pids.each do |pid|
              running = (not Process.getpgid(pid).nil?) rescue false
              waiting_pids.delete pid unless running
            end

            break if waiting_pids.empty?
            STDERR.write "."
            sleep 0.5
          end
          
          break if waiting_pids.empty?
          pids.replace waiting_pids
        end

        # Write a newline to clear the '.'s
        STDERR.write "\n"

        @logger.warn "Process(es) #{waiting_pids.inspect} did not terminate" unless waiting_pids.empty?
      end
  end
end