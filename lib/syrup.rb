require 'optparse'
require 'ostruct'
require 'syrup/daemon'
require 'syrup/manager'

module Syrup
  # The main application class for Syrup. Handles parsing of command line arguments, configuration, and
  # delegation to the appropriate control classes.
  class Application
    def self.version
      "0.0.1"
    end
    
    def run(arguments)
      # Configure defaults
      @options = OpenStruct.new
      @options.directory = File.expand_path('~/.syrup')
      @options.verbose = false
      
      # Parse the options
      @opts = build_options
      @opts.parse! arguments
      
      # Work out what command was issued
      command, command_args = determine_command(arguments)
      fail "No command given" if command.nil?
      
      # Ensure that the configured directory exists
      puts "INFO: Configured directory as #{@options.directory}" if $DEBUG
      FileUtils.mkdir_p @options.directory if not File.directory? @options.directory
      
      # Create a manager instance
      manager = Syrup::Manager.new @options.directory
      
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
          fail("No path given to run!") if command_args.length < 1
          manager.run command_args[0]
        else
          fail("Unrecognised command \"#{command}\"")
      end
    end
    
    def build_options
      opts = OptionParser.new
      opts.banner = "Usage: syrup [options] start | stop | run <path> | activate <path>"
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
      opts.on('-p', '--path PATH', "Sets the base path for this syrup configuration. Defaults to ~/.syrup") { |value| 
        @options.directory = value
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
          if arg =~ /^(\w+)=(.*)$/
            ENV[$1] = $2
          else
            command = arg unless arg =~ /^-/
          end
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
