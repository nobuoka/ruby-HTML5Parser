# coding: UTF-8

class HTML5Parser
module Token
  
  class TokenType
    def initialize( type_symbol )
      @type_symbol = type_symbol
    end
  end
  
  DOCTYPE_TYPE   = TokenType.new( :doctype_type   )
  START_TAG_TYPE = TokenType.new( :start_tag_type )
  END_TAG_TYPE   = TokenType.new( :end_tag_type   )
  CHARACTER_TYPE = TokenType.new( :character_type )
  COMMENT_TYPE   = TokenType.new( :comment_type   )
  EOF_TYPE       = TokenType.new( :eof_type       )
  
end
end
