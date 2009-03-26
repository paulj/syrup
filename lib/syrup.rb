require 'optparse'
require 'ostruct'
require 'syrup/daemon'
require 'syrup/manager'

module Syrup
  # The main application class for Syrup. Handles parsing of command line arguments, configuration, and
  # delegation to the appropriate control classes.
  class Application
    def self.version
      # Load the version from the VERSION.yml file
      version = YAML::load_file(File.join(File.dirname(__FILE__), '..', 'VERSION.yml'))
      
      "#{version[:major]}.#{version[:minor]}.#{version[:patch]}"
    end
    
    def run(arguments)
      # Configure defaults
      @options = OpenStruct.new
      @options.directory = File.expand_path('~/.syrup')
      @options.verbose = false
      @options.profile = "default"
      
      # Parse the options
      @opts = build_options
      @opts.parse! arguments
      
      # Work out what command was issued
      command, command_args = determine_command(arguments)
      fail "No command given" if command.nil?
      
      # Ensure that the configured directory exists
      puts "INFO: Configured directory as #{@options.directory}" if @options.verbose
      FileUtils.mkdir_p @options.directory if not File.directory? @options.directory
      
      # Create a manager instance
      manager = Syrup::Manager.new @options.directory, @options.profile, @options.verbose
      
      # Handle the command
      daemon = Syrup::Daemon.new @options.directory, manager
      case command
        when 'start'
          manager.start
        when 'stop'
          manager.stop
        when 'restart'
          manager.stop
          manager.start
        when 'activate'
          fail "No path given to activate!" if command_args.length < 1
          manager.activate command_args[0]
        when 'run'
          # Provide the command line if provided
          if command_args.length < 1
            manager.run
          else
            manager.run command_args[0]
          end
        when 'set'
          fail("No properties provided to set") if command_args.length < 1
          manager.set command_args
        when 'unset'
          fail("No properties provided to unset") if command_args.length < 1
          manager.unset command_args
        when 'clear'
          manager.clear
        when 'weave'
          fail("No fabric provided to weave") if command_args.length < 1
          manager.weave command_args[0]
        when 'unweave'
          manager.unweave
        else
          fail("Unrecognised command \"#{command}\"")
      end
    end
    
    def build_options
      opts = OptionParser.new
      opts.banner = "Usage: syrup [options] start | stop | run <path> | activate <path> | set <prop>=<value> |\n" +
                    "                       unset <prop> | clear | weave <fabric> | unweave"
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
      opts.on('--profile NAME', "Selects the profile that should be updated. Defaults to 'default'") { |value|
        @options.profile = value
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

  # Module Singleton methods
  class << self
    def application
      @application ||= Syrup::Application.new
    end
  end
end
