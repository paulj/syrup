# Support functions added to the kernel for Fabrics to work with
module Kernel
  # Indicates that a Fabric feature with the given name is required for the application to
  # proceed. If the feature is initialized on demand, then it is expected that this feature
  # will be initialized before this method returns.
  def fabric_requirement(name)
    Syrup.fabric_support.require_feature(name)
  end
end

module Syrup
  class FabricSupport
    def initialize
      @features = []
    end
    
    def require_feature(name)
      raise "Feature #{name} was not provided by the Fabric!" unless @features.include? name
    end
    
    def register_feature(name)
      @features << name
    end
  end
  
  class <<self
    def fabric_support
      @fabric_support ||= Syrup::FabricSupport.new
    end
  end
end