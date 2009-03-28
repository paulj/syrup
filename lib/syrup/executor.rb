module Syrup
  class Executor
    # Executes a script in the "foreground" (ie, it only forks once). The pid is recorded
    # in memory, and the process will return.
    def execute_foreground(name, script, fabric, props)
      
    end
    
    # Kills all processes running in the foreground.
    def kill_all_foreground
    end
    
    # Starts a script as a daemon. Returns the pid.
    def execute_daemon(name, script, fabric, props)
    end
    
    def stop_daemon(name, pid)
    end
  end
end