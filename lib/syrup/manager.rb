require 'yaml'

module Syrup
  # Manager for controlling the Syrup functionality
  class Manager
    def initialize(config_dir)
      @config_dir = config_dir
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
    def run path
      # Find the configuration file
      config = get_application_config path
      return false if config.nil?
      
      # Execute the configuration
      builder = execute_config path, config, :double_fork => false
      
      # Register an at_exit handler to kill off all the pids
      at_exit do
        builder.pids.each do |pid|
          pid && Process.kill("TERM", pid) rescue puts "WARNING: Failed to kill #{pid}"
        end
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
    
    private
      def activated_fn
        File.join @config_dir, 'activated'
      end
      
      def props_fn
        File.join @config_dir, 'props'
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
        # Apply any stored configuration value
        props = load_stored_properties
        props.each do |k,v|
          Kernel.const_set k, v
        end
        
        # Execute the application
        config_content = File.read config_fn
        builder = Syrup::Builder.new working_dir, @config_dir, args
        builder.instance_eval config_content
        
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
    
    def initialize(working_dir, config_dir, args)
      @working_dir = working_dir
      @config_dir = config_dir
      @double_fork = if args[:double_fork].nil? then true else args[:double_fork] end
      @pids = []
    end
    
    # Executes a rack based application
    def rack(name, command = "")
      in_fork(name) do
        require 'rubygems'
        require 'rack'
        ARGV.replace(command.split(' '))
        load 'rackup'
      end
    end

    # Executes a service based application
    def service(name, app, *args)
      in_fork (name) do
        # Execute the service app
        load app
      end
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
            STDOUT.reopen "logs/out.txt", "a"
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