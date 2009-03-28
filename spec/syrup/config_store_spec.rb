require 'syrup/config_store'
require 'fileutils'

describe Syrup::ConfigStore do
  before :each do
    # Ensure that we have a clear test data directory
    @path = File.join(File.dirname(__FILE__), '..', '..', 'test-data')
    FileUtils.rm_r @path if File.directory? @path
    FileUtils.mkdir_p @path
    
    # Create the store
    @store = Syrup::ConfigStore.new @path
  end
  
  it "should return an empty list of applications when unconfigured" do
    @store.applications.length.should == 0
  end
  
  it "should create an application when requested" do
    @store.create_application 'myapp'
    @store.applications['myapp'].should_not be_nil
  end
  
  it "should return the created application when one is created" do
    @store.create_application('myapp').name.should == 'myapp'
  end
  
  it "should return no properties on a new config" do
    @store.create_application 'myapp'
    @store.applications['myapp'].properties.length.should == 0
  end
  
  it "should allow properties to be stored in a global context" do
    @store.create_application 'myconfapp'
    @store.properties['a']= 'b'
    @store.properties['a'].should == 'b'
  end
  
  it "should allow properties to be cleared for the global content" do
    @store.create_application 'myconfapp'
    @store.properties['a']= 'b'
    @store.properties.clear
    @store.properties.length.should == 0
  end
  
  it "should allow properties to be deleted for the global context" do
    @store.create_application 'myconfapp'
    @store.properties['a']= 'b'
    @store.properties['b']= 'c'
    @store.properties.delete 'b'
    @store.properties.length.should == 1
    @store.properties['a'].should == 'b'
  end
  
  it "should allow all properties to be deleted for the global context" do
    @store.create_application 'myconfapp'
    @store.properties['a']= 'b'
    @store.properties['b']= 'c'
    @store.properties.delete 'a'
    @store.properties.delete 'b'
    @store.properties.length.should == 0
  end
  
  it "should return no properties on a new application" do
    @store.create_application 'myapp'
    @store.applications['myapp'].properties.length.should == 0
  end
  
  it "should allow properties to be stored for an application" do
    @store.create_application 'myconfapp'
    @store.applications['myconfapp'].properties['a']= 'b'
    @store.applications['myconfapp'].properties['a'].should == 'b'
  end
  
  it "should allow properties to be cleared for an application" do
    @store.create_application 'myconfapp'
    @store.applications['myconfapp'].properties['a']= 'b'
    @store.applications['myconfapp'].properties.clear
    @store.applications['myconfapp'].properties.length.should == 0
  end
  
  it "should allow properties to be deleted for an application" do
    @store.create_application 'myconfapp'
    @store.applications['myconfapp'].properties['a']= 'b'
    @store.applications['myconfapp'].properties['b']= 'c'
    @store.applications['myconfapp'].properties.delete 'b'
    @store.applications['myconfapp'].properties.length.should == 1
    @store.applications['myconfapp'].properties['a'].should == 'b'
  end

  it "should allow all properties to be deleted for an application" do
    @store.create_application 'myconfapp'
    @store.applications['myconfapp'].properties['a']= 'b'
    @store.applications['myconfapp'].properties['b']= 'c'
    @store.applications['myconfapp'].properties.delete 'a'
    @store.applications['myconfapp'].properties.delete 'b'
    @store.applications['myconfapp'].properties.length.should == 0
  end
  
  it "should return a nil fabric by default" do
    @store.fabric.should be_nil
  end
  
  it "should store the fabric location when set" do
    @store.fabric = '../myfabric'
    Syrup::ConfigStore.new(@path).fabric.should == File.expand_path('../myfabric')
  end
  
  it "should allow the fabric to be cleared" do
    @store.fabric = '../myfabric'
    @store.fabric = nil
    Syrup::ConfigStore.new(@path).fabric.should be_nil
  end

  it "should return a nil fabric by default for applications" do
    @store.create_application('myfabapp')
    @store.applications['myfabapp'].fabric.should be_nil
  end

  it "should store the fabric location when set for applications" do
    @store.create_application('myfabapp')
    @store.applications['myfabapp'].fabric = '../myappfabric'
    Syrup::ConfigStore.new(@path).applications['myfabapp'].fabric.should == File.expand_path('../myappfabric')
  end

  it "should allow the fabric to be cleared for application" do
    @store.create_application('myfabapp')
    @store.applications['myfabapp'].fabric = '../myappfabric'
    @store.applications['myfabapp'].fabric = nil
    Syrup::ConfigStore.new(@path).applications['myfabapp'].fabric.should be_nil
  end

  it "should return a nil application path by default for applications" do
    @store.create_application('myfabapp')
    @store.applications['myfabapp'].app.should be_nil
  end

  it "should store the application path when set for applications" do
    @store.create_application('myfabapp')
    @store.applications['myfabapp'].app = '../myapp.rb'
    Syrup::ConfigStore.new(@path).applications['myfabapp'].app.should == File.expand_path('../myapp.rb')
  end

  it "should allow the application path to be cleared for application" do
    @store.create_application('myfabapp')
    @store.applications['myfabapp'].app = '../myapp.rb'
    @store.applications['myfabapp'].app = nil
    Syrup::ConfigStore.new(@path).applications['myfabapp'].app.should be_nil
  end
  
  it "should return an empty list of start parameters for a new application" do
    @store.create_application('mynpapp')
    @store.applications['mynpapp'].start_parameters.should == []
  end
  
  it "should allow start parameters to be stored for an application" do
    @store.create_application('mypapp')
    @store.applications['mypapp'].start_parameters = ['param1', 'param 2']
    
    Syrup::ConfigStore.new(@path).applications['mypapp'].start_parameters.should == ['param1', 'param 2']
  end  
  
  it "should allow start parameters to be cleared for an application" do
    @store.create_application('mycapp')
    @store.applications['mycapp'].start_parameters = ['param1', 'param 2']
    @store.applications['mycapp'].start_parameters = []
    
    Syrup::ConfigStore.new(@path).applications['mycapp'].start_parameters.should == []
  end  
  
  it "should return a nil pid for a new application" do
    @store.create_application('mypidapp')
    @store.applications['mypidapp'].pid.should be_nil
  end
  
  it "should allow start parameters to be stored for an application" do
    @store.create_application('mypidapp')
    @store.applications['mypidapp'].pid = 1234
    
    Syrup::ConfigStore.new(@path).applications['mypidapp'].pid.should == 1234
  end  
  
  it "should allow the pid to be cleared for an application" do
    @store.create_application('mypidapp')
    @store.applications['mypidapp'].pid = 1234
    @store.applications['mypidapp'].pid = nil
    
    Syrup::ConfigStore.new(@path).applications['mypidapp'].pid.should be_nil
  end
end