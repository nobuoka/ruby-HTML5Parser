# coding: UTF-8

require 'html5_parser/token/doctype'
require 'html5_parser/token/start_tag'
require 'html5_parser/token/end_tag'
require 'html5_parser/token/comment'
require 'html5_parser/token/character'
require 'html5_parser/token/eof'

class HTML5Parser
class Tokenizer
  
  # Implementations must act as if they used the following state machine to tokenize HTML. 
  # The state machine must start in the data state. 
  # 
  # Tokenizer は状態機械の様にふるまうものである. 初期状態は data state である.
  
  # The output of the tokenization step is a series of zero or more of the following tokens: 
  #     DOCTYPE, 
  #     start tag, 
  #     end tag, 
  #     comment, 
  #     character, 
  #     end-of-file
  
  def initialize( tree_constructor )
    @input_stream = nil
    @tree_constructor = tree_constructor
    # これらは change_state メソッドで設定
    @current_state   = nil
    @current_handler = nil
    change_state ST_DATA
  end
  
  def set_input_stream( is )
    @input_stream = is
  end
  
  ###
  # 次の num 文字を返す.
  # EOF に達したばあい, num より少ない文字数を返す
  def get_next_chars( num )
    pos = @input_stream.pos
    s = ''
    begin
      num.times { s << @input_stream.readchar }
    rescue EOFError
    end
    @input_stream.pos = pos
    s
  end
  
  def consume_next_char()
    return @input_stream.readchar()
  rescue EOFError => err
    return ''
  end
  
  def reconsume_char( char )
    pos = @input_stream.pos - char.bytesize
    @input_stream.pos = pos
    @input_stream.print char
    @input_stream.pos = pos
    nil
  end
  
  def emit( token )
    @tree_constructor.handle_token( token )
  end
  
  def start()
    while true
      @current_handler.call()
    end
  rescue StopParsing
    @tree_constructor.stop_parsing()
  end
  
  def current_node
    @tree_constructor.current_node
  end
  
  HANDLER_NAMES = []
  def change_state( state )
    @current_state   = state
    @current_handler = method HANDLER_NAMES[ state ]
  end
  
  # 8.2.4.1 Data state
  ST_DATA = 1
  HANDLER_NAMES[ ST_DATA ] = :h_st_data
  def h_st_data
    # Consume the next input character:
    # U+0026 AMPERSAND (&)
    #   Switch to the character reference in data state.
    # U+003C LESS-THAN SIGN (<)
    #   Switch to the tag open state.
    # U+0000 NULL
    #   Parse error. Emit the current input character as a character token.
    # EOF
    #   Emit an end-of-file token.
    # Anything else
    #   Emit the current input character as a character token. 
    c = consume_next_char()
    case c
    when '&'
      change_state ST_CHARACTER_REFERENCE_IN_DATA
    when '<'
      change_state ST_TAG_OPEN
    when "\u0000"
      # TODO: parse error
      emit Token::Character.new( c )
    when '' # EOF
      emit Token::EOF.new()
    else
      emit Token::Character.new( c )
    end
  end
  
  # 8.2.4.8 Tag open state
  ST_TAG_OPEN = 8
  HANDLER_NAMES[ ST_TAG_OPEN ] = :h_st_tag_open
  def h_st_tag_open
    c = consume_next_char()
    case c
    when '!'
      change_state ST_MARKUP_DECLARATION_OPEN
    when '/'
      change_state ST_END_TAG_OPEN
    when 'A'..'Z'
      # Create a new start tag token, set its tag name to the lowercase version of the current 
      # input character (add 0x0020 to the character's code point), then switch to the tag name state. 
      # (Don't emit the token yet; further details will be filled in before it is emitted.)
      @current_tag_token = Token::TagStart.new( c.downcase )
      change_state ST_TAG_NAME
    when 'a'..'z'
      # Create a new start tag token, set its tag name to the current input character, 
      # then switch to the tag name state.
      # (Don't emit the token yet; further details will be filled in before it is emitted.)
      @current_tag_token = Token::TagStart.new( c )
      change_state ST_TAG_NAME
    when '?'
      # TODO: Parse error. 
      change_state ST_BOGUS_COMMENT
    else
      # TODO: Parse error. 
      change_state ST_DATA
      emit Token::Character.new( '<' )
      reconsume_char( c )
    end
  end
  
  # 8.2.4.45 Markup declaration open state
  ST_MARKUP_DECLARATION_OPEN = 45
  HANDLER_NAMES[ ST_MARKUP_DECLARATION_OPEN ] = :h_st_markup_declaration_open
  def h_st_markup_declaration_open()
    # If the next two characters are both U+002D HYPHEN-MINUS characters (-),
    # consume those two characters, create a comment token whose data is the empty string,
    # and switch to the comment start state.
    if '--' == get_next_chars( 2 )
      consume_next_char()
      consume_next_char()
      Token::Comment.new( '' )
      change_state ST_COMMENT_START
    
    # Otherwise, if the next seven characters are an ASCII case-insensitive match for the word "DOCTYPE",
    # then consume those characters and switch to the DOCTYPE state.
    elsif 'DOCTYPE' == get_next_chars( 7 ).upcase
      7.times { consume_next_char() }
      change_state ST_DOCTYPE
    
    else
    # Otherwise, if there is a current node and it is not an element in the HTML namespace 
    # and the next seven characters are a case-sensitive match for the string 
    # "[CDATA[" (the five uppercase letters "CDATA" with a U+005B LEFT SQUARE BRACKET 
    # character before and after), then consume those characters and switch to the CDATA section state.
    #elsif n = current_node and n.node_type
      
    #Otherwise, this is a parse error. Switch to the bogus comment state.
    # The next character that is consumed, if any, is the first character that will be in the comment.
      raise NotImplementedError.new()
    end
  end
  
  # 8.2.4.52 DOCTYPE state
  ST_DOCTYPE = 52
  HANDLER_NAMES[ ST_DOCTYPE ] = :h_st_doctype
  def h_st_doctype()
    c = consume_next_char()
    case c
    when "\u0009", "\u000A", "\u000C", "\u0020"
      change_state ST_BEFORE_DOCTYPE_NAME
    when '' # EOF
      raise NotImplementedError.new()
      # TODO: Parse error.
      change_state ST_DATA
      # Create a new DOCTYPE token.
      # Set its force-quirks flag to on.
      # Emit the token.
      # do nothing to reconsume the EOF character.
    else
      # TODO: Parse error.
      change_state ST_BEFORE_DOCTYPE_NAME
      reconsume_char( c )
    end
  end
  
  # 8.2.4.53 Before DOCTYPE name state
  ST_BEFORE_DOCTYPE_NAME = 53
  HANDLER_NAMES[ ST_BEFORE_DOCTYPE_NAME ] = :h_st_before_doctype_name
  def h_st_before_doctype_name()
    c = consume_next_char()
    case c
    when "\u0009", "\u000A", "\u000C", "\u0020"
      # ignore the character
    when 'A'..'Z'
      @current_doctype_token = Token::DOCTYPE.new()
      @current_doctype_token.name = c.downcase
      change_state ST_DOCTYPE_NAME
    when "\u0000"
      # TODO: Parse error.
      @current_doctype_token = Token::DOCTYPE.new()
      @current_doctype_token.name = "\uFFFD" # Set the token's name to a U+FFFD REPLACEMENT CHARACTER character.
      change_state ST_DOCTYPE_NAME
    when '>' # U+003E GREATER-THAN SIGN (>)
      # TODO: Parse error.
      t = Token::DOCTYPE.new()
      t.force_quirks_flag = true # Set its force-quirks flag to on.
      change_state ST_DATA
      emit t
    when '' # EOF
      # TODO: Parse error.
      change_state ST_DATA
      t = Token::DOCTYPE.new()
      t.force_quirks_flag = true # Set its force-quirks flag to on.
      emit t
      # do nothing to reconsume the EOF character.
    else
      @current_doctype_token = Token::DOCTYPE.new()
      @current_doctype_token.name = c
      change_state ST_DOCTYPE_NAME
    end
  end
  
  # 8.2.4.54 DOCTYPE name state
  ST_DOCTYPE_NAME = 54
  HANDLER_NAMES[ ST_DOCTYPE_NAME ] = :h_st_doctype_name
  def h_st_doctype_name()
    c = consume_next_char()
    case c
    when "\u0009", "\u000A", "\u000C", "\u0020"
      change_state ST_AFTER_DOCTYPE_NAME
    when '>'
      change_state ST_DATA
      emit @current_doctype_token
    when 'A'..'Z'
      @current_doctype_token.name << c.downcase
    when "\u0000"
      # TODO: Parse error.
      # Append a U+FFFD REPLACEMENT CHARACTER character to the current DOCTYPE token's name.
      @current_doctype_token.name << "\uFFFD"
    when '' # EOF
      # TODO: Parse error.
      change_state ST_DATA
      @current_doctype_token.force_quirks_flag = true # Set the DOCTYPE token's force-quirks flag to on.
      emit @current_doctype_token
      # do nothing to reconsume the EOF character.
    else
      @current_doctype_token.name << c
    end
  end
  
=begin
    8.2.4.2 Character reference in data state
    8.2.4.3 RCDATA state
    8.2.4.4 Character reference in RCDATA state
    8.2.4.5 RAWTEXT state
    8.2.4.6 Script data state
    8.2.4.7 PLAINTEXT state
    8.2.4.8 Tag open state
    8.2.4.9 End tag open state
    8.2.4.10 Tag name state
    8.2.4.11 RCDATA less-than sign state
    8.2.4.12 RCDATA end tag open state
    8.2.4.13 RCDATA end tag name state
    8.2.4.14 RAWTEXT less-than sign state
    8.2.4.15 RAWTEXT end tag open state
    8.2.4.16 RAWTEXT end tag name state
    8.2.4.17 Script data less-than sign state
    8.2.4.18 Script data end tag open state
    8.2.4.19 Script data end tag name state
    8.2.4.20 Script data escape start state
    8.2.4.21 Script data escape start dash state
    8.2.4.22 Script data escaped state
    8.2.4.23 Script data escaped dash state
    8.2.4.24 Script data escaped dash dash state
    8.2.4.25 Script data escaped less-than sign state
    8.2.4.26 Script data escaped end tag open state
    8.2.4.27 Script data escaped end tag name state
    8.2.4.28 Script data double escape start state
    8.2.4.29 Script data double escaped state
    8.2.4.30 Script data double escaped dash state
    8.2.4.31 Script data double escaped dash dash state
    8.2.4.32 Script data double escaped less-than sign state
    8.2.4.33 Script data double escape end state
    8.2.4.34 Before attribute name state
    8.2.4.35 Attribute name state
    8.2.4.36 After attribute name state
    8.2.4.37 Before attribute value state
    8.2.4.38 Attribute value (double-quoted) state
    8.2.4.39 Attribute value (single-quoted) state
    8.2.4.40 Attribute value (unquoted) state
    8.2.4.41 Character reference in attribute value state
    8.2.4.42 After attribute value (quoted) state
    8.2.4.43 Self-closing start tag state
    8.2.4.44 Bogus comment state
    8.2.4.45 Markup declaration open state
    8.2.4.46 Comment start state
    8.2.4.47 Comment start dash state
    8.2.4.48 Comment state
    8.2.4.49 Comment end dash state
    8.2.4.50 Comment end state
    8.2.4.51 Comment end bang state
    8.2.4.52 DOCTYPE state
    8.2.4.53 Before DOCTYPE name state
    8.2.4.54 DOCTYPE name state
    8.2.4.55 After DOCTYPE name state
    8.2.4.56 After DOCTYPE public keyword state
    8.2.4.57 Before DOCTYPE public identifier state
    8.2.4.58 DOCTYPE public identifier (double-quoted) state
    8.2.4.59 DOCTYPE public identifier (single-quoted) state
    8.2.4.60 After DOCTYPE public identifier state
    8.2.4.61 Between DOCTYPE public and system identifiers state
    8.2.4.62 After DOCTYPE system keyword state
    8.2.4.63 Before DOCTYPE system identifier state
    8.2.4.64 DOCTYPE system identifier (double-quoted) state
    8.2.4.65 DOCTYPE system identifier (single-quoted) state
    8.2.4.66 After DOCTYPE system identifier state
    8.2.4.67 Bogus DOCTYPE state
    8.2.4.68 CDATA section state
    8.2.4.69 Tokenizing character references
=end
  
end
end
