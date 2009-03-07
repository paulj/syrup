require 'fileutils'

module Syrup
  class Daemon
    def initialize(config_directory, app)
      @config_directory = config_directory
      @app = app
    end
    
    def start
      # Check if the process is already running first
      if File.file? pid_fn
        running = (not Process.getpgid(recall_pid).nil?) rescue false
        if running
          puts "Syrup is already running. Stop Syrup before trying to start it"
          exit
        end
      end
      
      fork do
        Process.setsid
        exit if fork
        store_pid(Process.pid)
        #Dir.chdir WorkingDirectory
        File.umask 0000
        STDIN.reopen "/dev/null"
        STDOUT.reopen "/dev/null", "a"
        STDERR.reopen STDOUT
        trap("TERM") {@app.stop; exit}
        @app.start
      end
    end
  
    def stop
      if !File.file?(pid_fn)
        puts "Pid file not found. Is the daemon started?"
        exit
      end
      pid = recall_pid
      FileUtils.rm(pid_fn)
      pid && Process.kill("TERM", pid)
    end
    
    private
      def pid_fn
        File.join(File.expand_path(@config_directory), 'syrup.pid')
      end
    
      def store_pid(pid)
        FileUtils.mkdir_p File.dirname(pid_fn)
        File.open(pid_fn, 'w') {|f| f << pid}
      end

      def recall_pid
        IO.read(pid_fn).to_i rescue nil
      end
  end
end