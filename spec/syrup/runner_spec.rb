require 'syrup/runner'

describe Syrup::Runner do
  before(:each) do
    # Wire all the stubs
    @app_name = 'mytestapp'
    @config_store = mock('config_store')
    @app = mock('application')
    @config_store.stub!(:applications).and_return({'mytestapp' => @app})
    @logger = mock('logger', :null_object => true)
    
    # Create the runner
    @runner = Syrup::Runner.new(@config_store, @logger)
  end
  
  it "should run the default fabric when neither the application nor the global environment define a fabric" do
    @app.stub!(:properties).and_return({})
    @config_store.stub!(:properties).and_return({})
    @app.stub!(:fabric).and_return nil
    @config_store.stub!(:fabric).and_return nil
    @app.stub!(:app).and_return nil
    @app.stub!(:start_parameters).and_return []
    
    SyrupKernelSim.simulating do
      @runner.run @app_name
    end
    
    SyrupKernelSim.load_list.length.should == 1
    File.expand_path(SyrupKernelSim.load_list[0]).should == File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib', 'syrup', 'fabrics', 'default.rb'))
  end
  
  it "should run the global environment fabric if the application does not specify one" do
    @app.stub!(:properties).and_return({})
    @config_store.stub!(:properties).and_return({})
    @app.stub!(:fabric).and_return nil
    @config_store.stub!(:fabric).and_return 'globalfabric.rb'
    @app.stub!(:app).and_return nil
    @app.stub!(:start_parameters).and_return []
    
    SyrupKernelSim.simulating do
      @runner.run @app_name
    end
    
    SyrupKernelSim.load_list.should == ['globalfabric.rb']
  end
    
  it "should run the application fabric even if the global environment specifies one" do
    @app.stub!(:properties).and_return({})
    @config_store.stub!(:properties).and_return({})
    @app.stub!(:fabric).and_return 'appfabric.rb'
    @config_store.stub!(:fabric).and_return 'globalfabric.rb'
    @app.stub!(:app).and_return nil
    @app.stub!(:start_parameters).and_return []
    
    SyrupKernelSim.simulating do
      @runner.run @app_name
    end
    
    SyrupKernelSim.load_list.should == ['appfabric.rb']
  end
    
  it "should run the application fabric even if the global environment doesn't specify one" do
    @app.stub!(:properties).and_return({})
    @config_store.stub!(:properties).and_return({})
    @app.stub!(:fabric).and_return 'appfabric.rb'
    @config_store.stub!(:fabric).and_return nil
    @app.stub!(:app).and_return nil
    @app.stub!(:start_parameters).and_return []
    
    SyrupKernelSim.simulating do
      @runner.run @app_name
    end
    
    SyrupKernelSim.load_list.should == ['appfabric.rb']
  end

  it "should not support invoking the application outside of the fabric" do
    lambda {@runner.run_application}.should raise_error("Cannot execute application outside of Fabric")
  end

  it "should support invoking the application whilst the fabric is running" do
    @app.stub!(:properties).and_return({})
    @config_store.stub!(:properties).and_return({})
    @app.stub!(:fabric).and_return 'appfabric.rb'
    @config_store.stub!(:fabric).and_return nil
    @app.stub!(:app).and_return 'myapp.rb'
    @app.stub!(:start_parameters).and_return []
    
    SyrupKernelSim.simulating do
      SyrupKernelSim.register_load_handler do |name|
        # Run the application if we're simulating the run of the fabric
        Syrup::Runner.run_application if name == 'appfabric.rb'
      end
      
      @runner.run @app_name
    end
    
    SyrupKernelSim.load_list.should == ['appfabric.rb', 'myapp.rb']
  end
  
  it "should overwrite ARGV whilst the application is running" do
    @app.stub!(:properties).and_return({})
    @config_store.stub!(:properties).and_return({})
    @app.stub!(:fabric).and_return 'appfabric.rb'
    @config_store.stub!(:fabric).and_return nil
    @app.stub!(:app).and_return 'myapp.rb'
    @app.stub!(:start_parameters).and_return ['a', 'b']
    
    SyrupKernelSim.simulating do
      SyrupKernelSim.register_load_handler do |name|
        # Ensure that ARGV has been set properly
        ARGV.should == ['a', 'b']
      end
      
      @runner.run @app_name
    end
  end  
  
  it "should restore ARGV after the application has run" do
    @app.stub!(:properties).and_return({})
    @config_store.stub!(:properties).and_return({})
    @app.stub!(:fabric).and_return 'appfabric.rb'
    @config_store.stub!(:fabric).and_return nil
    @app.stub!(:app).and_return 'myapp.rb'
    @app.stub!(:start_parameters).and_return ['a', 'b']
    
    SyrupKernelSim.simulating do
      @runner.run @app_name
    end
    
    ARGV.should_not == ['a', 'b']
  end
  
  it "should set the global properties" do
    @app.stub!(:properties).and_return({})
    @config_store.stub!(:properties).and_return({'A' => 1, 'B' => 2})
    @app.stub!(:fabric).and_return 'appfabric.rb'
    @config_store.stub!(:fabric).and_return nil
    @app.stub!(:app).and_return nil
    @app.stub!(:start_parameters).and_return []
    
    SyrupKernelSim.simulating do
      @runner.run @app_name
    end
    
    SyrupKernelSim.consts.length.should == 2
    SyrupKernelSim.consts['A'].should == 1
    SyrupKernelSim.consts['B'].should == 2
  end
  
  it "should set the application properties" do
    @app.stub!(:properties).and_return({'A' => 1, 'B' => 2})
    @config_store.stub!(:properties).and_return({})
    @app.stub!(:fabric).and_return 'appfabric.rb'
    @config_store.stub!(:fabric).and_return nil
    @app.stub!(:app).and_return nil
    @app.stub!(:start_parameters).and_return []
    
    SyrupKernelSim.simulating do
      @runner.run @app_name
    end
    
    SyrupKernelSim.consts.length.should == 2
    SyrupKernelSim.consts['A'].should == 1
    SyrupKernelSim.consts['B'].should == 2
  end
  
  it "should mix global and application properties, and application properties should take precendence" do
    @app.stub!(:properties).and_return({'B' => 3, 'C' => 4})
    @config_store.stub!(:properties).and_return({'A' => 1, 'B' => 2})
    @app.stub!(:fabric).and_return 'appfabric.rb'
    @config_store.stub!(:fabric).and_return nil
    @app.stub!(:app).and_return nil
    @app.stub!(:start_parameters).and_return []
    
    SyrupKernelSim.simulating do
      @runner.run @app_name
    end
    
    SyrupKernelSim.consts.length.should == 3
    SyrupKernelSim.consts['A'].should == 1
    SyrupKernelSim.consts['B'].should == 3
    SyrupKernelSim.consts['C'].should == 4
  end
end

class SyrupKernelSim
  def self.simulating
    load_list.clear
    @simulating = true
    yield ensure @simulating, @load_handler = false, nil
  end

  def self.is_simulating?
    @simulating
  end
  
  def self.file_loaded(name)
    load_list << name
    
    # Invoke any registered handlers
    if @load_handler
      @load_handler.call(name)
    end
  end
  
  def self.load_list
    @load_list ||= []
  end
  
  def self.consts
    @consts ||= {}
  end
  
  def self.register_load_handler(&handler)
    raise "Cannot add load handler when not simulating!" if not @simulating
    
    @load_handler = handler
  end
end

# Patch Kernel so we can intercept load events
module Kernel
  alias :syrup_original_load :load
  
  def load(name)
    # Just forward to the real method if we're not simulating
    return syrup_original_load(name) if not SyrupKernelSim.is_simulating?
    
    # Oterhwise, record the value, and tell the simulator to invoke any handler
    SyrupKernelSim.file_loaded(name) if SyrupKernelSim.is_simulating?
  end
end
class Module
  alias :syrup_original_const_set :const_set

  def const_set(k, v)
    # Just forward to the real method if we're not simulating
    return syrup_original_const_set(k, v) if not SyrupKernelSim.is_simulating?
    
    # Otherwise, record the value
    SyrupKernelSim.consts[k] = v
  end
end