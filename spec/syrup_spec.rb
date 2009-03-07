$:.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'syrup'

describe "Syrup::Application" do
  it "should report a version" do
    Syrup::Application.version.should_not be_nil
  end
end