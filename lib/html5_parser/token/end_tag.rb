# coding: UTF-8

require 'html5_parser/token'

class HTML5Parser
module Token
class EndTag
  
  # Start and end tag tokens have a tag name, a self-closing flag, and a list of attributes, each of which 
  # has a name and a value. 
  # When a start or end tag token is created, 
  #   its self-closing flag must be unset (its other state is that it be set), and 
  #   its attributes list must be empty. 
  
  def initialize( tag_name )
    @tag_name = tag_name
    @self_closing_flag = false
    @attributes = []
  end
  
  def type
    END_TAG_TYPE
  end
  
  def tag_name
    @tag_name
  end
  
  def self_closing_flag
    @self_closing_flag
  end
  
  def attributes
    @attributes
  end
  
end
end
end
