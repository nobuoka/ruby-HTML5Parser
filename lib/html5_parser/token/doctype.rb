# coding: UTF-8

require 'html5_parser/token'

class HTML5Parser
module Token
class DOCTYPE
  
  # DOCTYPE tokens have a name, a public identifier, a system identifier, and a force-quirks flag.
  # When a DOCTYPE token is created, its name, public identifier, and system identifier must be marked 
  # as missing (which is a distinct state from the empty string), and the force-quirks flag must be set to 
  # off (its other state is on). 
  
  def initialize
    @name = nil
    @public_identifier = nil
    @system_identifier = nil
    @force_quirks_flag = false
  end
  
  def type
    DOCTYPE_TYPE
  end
  
  def name
    @name
  end
  
  def public_identifier
    @public_identifier
  end
  
  def system_identifier
    @system_identifier
  end
  
  def force_quirks_flag
    @force_quirks_flag
  end
  
end
end
end
