# coding: UTF-8

require 'html5_parser/token'

class HTML5Parser
module Token
class Comment
  
  # Comment and character tokens have data.
  
  def initialize( data )
    @data = data
  end
  
  def type
    COMMENT_TYPE
  end
  
  def data
    @data
  end
  
end
end
end
