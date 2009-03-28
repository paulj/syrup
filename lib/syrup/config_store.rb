module Syrup
  # Module that allows a given object to store a Fabric. Requires the including module to have
  # a fabric_fn method.
  module WithFabric
    def fabric
      return File.read(fabric_fn) if File.file? fabric_fn
      return nil
    end
    
    def fabric=(path)
      unless path.nil?
        File.open(fabric_fn, 'w'){ |f| f.write(File.expand_path(path)) }
      else
        File.delete fabric_fn if File.file? fabric_fn
      end
    end
  end
  
  class ConfigStore
    include WithFabric
    
    attr_reader :properties
    
    # Initializes the configuration store with the given storage directory.
    def initialize(path)
      @path = path
      @properties = StoredHash.new File.join(@path, 'props')
    end
    
    # Retrieves all of the applications that are configured within the system
    def applications
      apps = {}
      Dir[File.join(@path, '*')].each do |store_dir|
        name = File.basename(store_dir)
        
        apps[name] = ApplicationConfiguration.new name, store_dir
      end
      
      apps
    end
    
    # Creates a new application
    def create_application(name)
      store_dir = File.join(@path, name)
      FileUtils.mkdir_p store_dir
      
      ApplicationConfiguration.new name, store_dir
    end
    
    def fabric_fn
      File.join(@path, 'fabric')
    end
  end
  
  class ApplicationConfiguration
    include WithFabric
    
    attr_reader :name
    attr_reader :properties
    
    def initialize(name, path)
      @name = name
      @path = path
      @properties = StoredHash.new File.join(@path, 'props')
      @start_parameters = if File.file? start_params_fn then YAML::load_file(start_params_fn) else [] end
    end

    def app
      return File.read(activated_fn) if File.file? activated_fn
      return nil
    end
    
    def app=(path)
      unless path.nil?
        File.open(activated_fn, 'w'){ |f| f.write(File.expand_path(path)) }
      else
        File.delete activated_fn if File.file? activated_fn
      end
    end
    
    def pid
      result = File.read(pid_fn) rescue nil
      return result.to_i unless result.nil?
      
      nil
    end
    
    def pid=(i)
      unless i.nil?
        File.open(pid_fn, 'w'){ |f| f.write(i) }
      else
        File.delete pid_fn if File.file? pid_fn
      end
    end
    
    def start_parameters
      @start_parameters
    end
    
    def start_parameters=(params)
      @start_parameters = params
      
      unless params.nil? or params.length == 0
        File.open(start_params_fn, 'w') { |f| f.write(params.to_yaml) }
      else
        File.delete start_params_fn if File.file? start_params_fn
      end
    end

    def activated_fn
      File.join(@path, 'activated')
    end
    
    def props_fn
      File.join(@path, 'props')
    end

    def fabric_fn
      File.join(@path, 'fabric')
    end
    
    def start_params_fn
      File.join(@path, 'start_params')
    end
    
    def pid_fn
      File.join(@path, 'pid')
    end
  end
  
  class StoredHash
    def initialize(file)
      @file = file
      @props = if File.file? file then YAML::load_file(file) else {} end
    end
    
    def [](k)
      @props[k]
    end
    
    def []=(k, v)
      @props[k] = v
      
      save!
    end
    
    def length
      @props.length
    end
    
    def clear
      @props.clear
      File.delete @file if File.file? @file
    end
    
    def delete(key)
      @props.delete(key)
      save!
    end
    
    def each(&block)
      @props.each(&block)
    end
    
    def save!
      File.open(@file, 'w') {|f| f << @props.to_yaml}
    end
  end
end