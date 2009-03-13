require 'yaml'

module Syrup
  # Manager for controlling the Syrup functionality
  class Manager
    def initialize(config_dir, profile, verbose)
      @config_dir = config_dir
      @profile = profile
      @verbose = verbose
    end
    
    # Informs the manager to start the configured application
    def start
      # Test that we have an activated configuration
      if not File.file? activated_fn 
        puts 'WARNING: No Application activated yet. Nothing to do!'
        return true
      end
      
      # Load the path of the configured app from the 'activated' file
      config = get_application_config File.read(activated_fn)
      return false if config.nil?
      
      # Execute the application
      execute_config File.dirname(config), config
      
      return true
    end
    
    # Informs the manager to stop all configured applications
    def stop
      # Work through each pid in the configuration directory, and kill it
      pids = []
      Dir[File.join(@config_dir, '*.pid')].each do |pid_f|
        pid = IO.read(pid_f).to_i rescue nil
        FileUtils.rm pid_f
        pids << pid
      end
      
      # Wait for the process to die
      kill_pids pids
    end
    
    # Informs the manager to activate the given path
    def activate path
      # Test the path
      config = get_application_config path
      if config.nil?
        return false
      end
      
      # Update the activated file name
      File.open(activated_fn, 'w'){ |f| f.write(File.expand_path(path)) }
      
      true
    end
    
    # Informs the manager to run the given path in the foreground, as if it were an activated path
    def run path = nil
      # Use the activated path if the provided one is nil
      if path.nil?
        config = get_application_config(File.read(activated_fn))
        return false if config.nil?
      else
        # Find the configuration file
        config = get_application_config path
        return false if config.nil?
      end
      
      # Execute the configuration
      builder = execute_config File.dirname(config), config, :double_fork => false
      
      # Register an at_exit handler to kill off all the pids
      at_exit do
        kill_pids builder.pids
      end
      
      # Wait for all children to die
      Process.waitall.each do |pid, status|
        # We won't need to kill the processes that successfully exited
        builder.pids.delete pid if status.exited?
      end
    end
    
    # Requests that the manager store the given variables as persistent configuration that will be
    # restored when applications are started
    def set(props)
      current = load_stored_properties
      props.each do |pair|
        k,v = pair.split('=')
        if k.nil? or v.nil?
          puts "ERROR: Invalid set command. #{pair} not in the form K=V"
          return false
        end
        
        current[k] = v
      end
      
      File.open(props_fn, 'w') {|f| f << current.to_yaml}
    end
    
    # Requests that the manager remove the given keys from the stored properties
    def unset(props)
      current = load_stored_properties
      props.each do |prop|
        current.delete prop
      end
      
      File.open(props_fn, 'w') {|f| f << current.to_yaml}
    end
    
    # Removes all stored properties for the current profile
    def clear
      File.delete props_fn
    end
    
    # Requests that the manager load the given fabric for applications within the current profile
    def weave(fabric)
      # Update the fabric file name
      File.open(fabric_fn, 'w'){ |f| f.write(File.expand_path(fabric)) }
    end
    
    # Requests that the manager stop loading any custom fabric for the current profile, and instead
    # load the default fabric
    def unweave
      File.delete(fabric_fn)
    end
    
    private
      def activated_fn
        File.join @config_dir, "#{@profile}.activated"
      end
      
      def props_fn
        File.join @config_dir, "#{@profile}.props"
      end
      
      def fabric_fn
        File.join @config_dir, "#{@profile}.fabric"
      end
      
      def get_application_config(path)
        config = File.join path, 'config.sy'
        if not File.file? config
          puts "ERROR: #{config} does not exist!"
          return nil
        end
        
        config
      end
      
      def execute_config working_dir, config_fn, args = {}
        puts "DEBUG: Loading configuration #{config_fn}" if @verbose
        
        # Apply any stored configuration value
        props = load_stored_properties
        props.each do |k,v|
          put "DEBUG: Applying constant #{k}=#{v}" if @verbose
          Kernel.const_set k, v
        end
        
        # Load the application config
        config_content = File.read config_fn
        builder = Syrup::Builder.new working_dir, @config_dir, args
        
        # Load the fabric
        if File.file? fabric_fn
          fabric_file = File.read fabric_fn
          puts "DEBUG: Applying fabric #{fabric_file}" if @verbose
        else
          fabric_file = File.join File.dirname(__FILE__), 'fabrics', 'default.rb'
          puts "DEBUG: Applying default fabric"
        end
        builder.instance_eval File.read(fabric_file), fabric_file
        
        # Execute the application configuration script
        builder.instance_eval config_content, config_fn
        
        builder
      end
      
      def load_stored_properties
        current = if File.file? props_fn then YAML.load_file(props_fn) else {} end
        current ||= {}
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

        puts "WARNING: Process(es) #{waiting_pids.inspect} did not terminate" unless waiting_pids.empty?
      end
  end
  
  # Builder class used to activate the applications
  class Builder 
    attr_reader :pids
    
    def self.instance
      @@instance
    end
    
    def initialize(working_dir, config_dir, args)
      @working_dir = working_dir
      @config_dir = config_dir
      @double_fork = if args[:double_fork].nil? then true else args[:double_fork] end
      @pids = []
      
      # Record the current instance
      @@instance = self
    end
    
    # Defines an application type that can be declared in a config.sy file.
    def define_application_type(name, &block)
      raise "No block provided for application type" unless block_given?
      
      # Define a method with the given name in our class
      metaclass = class << self; self; end
      metaclass.send(:define_method, name, &block)
    end
    
    def define(&block)
      raise "No block provided" unless block_given?
      
      instance_eval(&block)
    end
    
    private
      def in_fork(name, &block)
        pid = fork do
          if not @double_fork
            Dir.chdir @working_dir
            trap("TERM") {exit}
            yield block
          else 
            Process.setsid
            exit if fork
            store_pid(name, Process.pid)
            Dir.chdir @working_dir
            File.umask 0000
            STDIN.reopen "/dev/null"
            STDOUT.reopen "log/#{name}.txt", "a"
            STDERR.reopen STDOUT
            trap("TERM") {exit}
            yield block
            remove_pid name
          end
        end
        
        # If we didn't double-fork, then record the PID
        @pids << pid if not @double_fork 
      end
      
      def store_pid name, pid
        File.open(pid_fn(name), 'w') {|f| f << pid}
      end
      
      def remove_pid name
        FileUtils.rm(pid_fn(name))
      end
      
      def pid_fn name
        File.join @config_dir, "#{name}.pid"
      end
  end
end