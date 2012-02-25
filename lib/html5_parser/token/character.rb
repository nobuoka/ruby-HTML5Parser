# coding: UTF-8

require 'html5_parser/token'

class HTML5Parser
module Token
class Character
  
  # Comment and character tokens have data.
  
  def initialize( data )
    @data = data
  end
  
  def type
    CHARACTER_TYPE
  end
  
  def data
    @data
  end
  
end
end
end
