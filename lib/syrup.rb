require 'optparse'
require 'ostruct'
require 'syrup/daemon'
require 'syrup/manager'
require 'syrup/runner'
require 'syrup/fabric_support'

module Syrup
  # The main application class for Syrup. Handles parsing of command line arguments, configuration, and
  # delegation to the appropriate control classes.
  class Application
    def self.version
      # Load the version from the VERSION.yml file
      version = YAML::load_file(File.join(File.dirname(__FILE__), '..', 'VERSION.yml'))
      
      "#{version[:major]}.#{version[:minor]}.#{version[:patch]}"
    end

    def self.logger
      @logger ||= Syrup::Logger.new
    end
    
    def run(arguments)
      # Get the logger
      logger = Syrup::Application.logger
      
      # Configure defaults
      @options = OpenStruct.new
      @options.directory = File.expand_path('~/.syrup')
      @options.verbose = false
      @options.application = nil
      
      # Parse the options
      @opts = build_options
      @opts.parse! arguments
      
      # Work out what command was issued
      command, command_args = determine_command(arguments)
      fail "No command given" if command.nil?
      
      # Ensure that the configured directory exists
      logger.info "Configured directory as #{@options.directory}" if @options.verbose
      FileUtils.mkdir_p @options.directory if not File.directory? @options.directory
      
      # Create a manager instance
      manager = Syrup::Manager.new @options.directory, logger, @options.verbose
      
      # Handle the command
      daemon = Syrup::Daemon.new @options.directory, manager
      case command
        when 'start'
          if command_args.length < 1
            manager.start_all
          else
            command_args.each { |arg| manager.start arg }
          end
        when 'stop'
          if command_args.length < 1
            manager.stop_all
          else
            manager.stop(command_args)
          end
        when 'restart'
          if command_args.length < 1
            manager.stop_all
            manager.start_all
          else
            command_args.each { |arg| manager.stop arg }
            command_args.each { |arg| manager.start arg }
          end
        when 'activate'
          fail "No application given to activate a script for!" if command_args.length < 1
          fail "No path given to activate!" if command_args.length < 2
          manager.activate command_args[0], command_args[1], command_args.slice(2, command_args.length - 2)
        when 'run'
          # Provide the command line if provided
          if command_args.length < 1
            manager.run_all
          else
            manager.run command_args
          end
        # when 'run_app'
        #   fail('No application name provided') if command_args.length == 0
        #   manager.run_app command_args[0] #, command_args.slice(1, command_args.length - 1)
        when 'set'
          fail("No properties provided to set") if command_args.length < 1
          if @options.application
            manager.set_app_properties @options.application, command_args
          else
            manager.set_global_properties command_args
          end
        when 'unset'
          fail("No properties provided to unset") if command_args.length < 1
          if @options.application
            manager.unset_app_properties @options.application, command_args
          else
            manager.unset_global_properties command_args
          end
        when 'clear'
          if @options.application
            manager.clear_app_properties @options.application
          else
            manager.clear_global_properties
          end
        when 'weave'
          fail("No fabric provided to weave") if command_args.length < 1
          if @options.application
            manager.weave_for_application @options.application, command_args[0]
          else
            manager.weave_global command_args[0]
          end
        when 'unweave'
          if @options.application
            manager.unweave_for_application @options.application
          else
            manager.unweave_global
          end
        else
          fail("Unrecognised command \"#{command}\"")
      end
    end
    
    def build_options
      opts = OptionParser.new
      opts.banner = "Usage: syrup [options] start [name] | stop [name] | run [<path> | name] | activate [name] <path> |\n" +
                    "                       set <prop>=<value> | unset <prop> | clear | weave <fabric> | unweave"
      opts.separator ""
      opts.separator "Ruby options:"
      opts.on('-d', '--debug', 'set debugging flags (set $DEBUG to true)') { $DEBUG = true }
      opts.on("-I", "--include PATH", "specify $LOAD_PATH (may be used more than once)") { |path|
        $LOAD_PATH.unshift(*path.split(":"))
      }
      opts.on("-r", "--require LIBRARY", "require the library, before executing your script") { |library|
        require library
      }
      
      opts.separator ""
      opts.separator "Syrup options:"
      opts.on('-p', '--path PATH', "Sets the base path for this syrup configuration. Defaults to ~/.syrup. See also the --local option to set this") { |value| 
        @options.directory = value
      }
      opts.on('--local', "Sets the configuration base path to ./.syrup, allowing for a local configuration") {
        @options.directory = File.expand_path('./.syrup')
      }
      opts.on('--application NAME', "Selects the application that should be updated. Defaults to global settings.") { |value|
        @options.application = value
      }
      opts.on('--verbose', "Places Syrup in verbose mode.") {
        @options.verbose = true
      }
      
      opts.separator ""
      opts.separator "Common options:"
      opts.on_tail("-h", "--help", "Show this message") { puts opts; exit 0 }
      opts.on_tail('-v', '--version', "Print the version and exit") { output_version; exit 0 }
      
      opts
    end
    
    # Determines the command issued in the provided arguments
    def determine_command(arguments)
      command = nil
      command_args = []
      
      # Work through each argument until we reach the command. Then, consume everything
      # after it as arguments to the command
      arguments.each do |arg|
        if command.nil?
          command = arg unless arg =~ /^-/
        else
          command_args << arg
        end
      end
      
      return command, command_args
    end
    
    # Outputs the version
    def output_version
      puts "Syrup version #{Syrup::Application.version}"
    end
    
    def fail(msg)
      puts "ERROR: #{msg}"
      puts @opts
      exit
    end
  end
  
  class Logger
    def error(msg)
      puts "ERROR: #{msg}"
    end
    def warn(msg)
      puts "WARN: #{msg}"
    end
    def info(msg)
      puts "INFO: #{msg}"
    end
    def debug(msg)
      puts "DEBUG: #{msg}"
    end
  end

  # Module Singleton methods
  class << self
    def application
      @application ||= Syrup::Application.new
    end
  end
end
