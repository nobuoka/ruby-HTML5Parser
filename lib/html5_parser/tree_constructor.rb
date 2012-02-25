# coding: UTF-8

require 'html5_parser/token/doctype'
require 'html5_parser/token/start_tag'
require 'html5_parser/token/end_tag'
require 'html5_parser/token/comment'
require 'html5_parser/token/character'
require 'html5_parser/token/eof'

class HTML5Parser
class TreeConstructor
  
  # The input to the tree construction stage is a sequence of tokens from the tokenization stage. 
  # The tree construction stage is associated with a DOM Document object when a parser is created. 
  # The "output" of this stage consists of dynamically modifying or extending that document's DOM tree.
  
  # === insertion modes ===
  IM_INITIAL              = 1
  IM_BEFORE_HTML          = 2
  IM_BEFORE_HEAD          = 3
  IM_IN_HEAD              = 4
  IM_IN_HEAD_NOSCRIPT     = 5
  IM_AFTER_HEAD           = 6
  IM_IN_BODY              = 7
  IM_TEXT                 = 8
  IM_IN_TABLE             = 9
  IM_IN_TABLE_TEXT        = 10
  IM_IN_CAPTION           = 11
  IM_IN_COLUMN_GROUP      = 12
  IM_IN_TABLE_BODY        = 13
  IM_IN_ROW               = 14
  IM_IN_CELL              = 15
  IM_IN_SELECT            = 16
  IM_SELECT_IN_TABLE      = 17
  IM_AFTER_BODY           = 18
  IM_IN_FRAMESET          = 19
  IM_AFTER_FRAMESET       = 20
  IM_AFTER_AFTER_BODY     = 21
  IM_AFTER_AFTER_FRAMESET = 22
  
  HTML_NS = 'http://www.w3.org/1999/xhtml'
  
  def initialize( parser )
    @doc    = nil
    @parser = parser
    @stack_of_open_elements = []
    # これらは change_insertion_mode メソッドで設定
    @insertion_mode  = nil
    @current_handler = nil
    change_insertion_mode IM_INITIAL
    @head_elem_pointer = nil
  end
  
  def set_document( doc )
    @doc = doc
  end
  
  def handle_token( token )
    @current_handler.call( token )
  end
  
  def push_elem_in_stack_of_open_elems( elem )
    @stack_of_open_elements.push( elem )
  end
  
  # Pop the current node (which will be the head element) off the stack of open elements.
  def pop_current_node_off_stack_of_open_elems()
    @stack_of_open_elements.pop()
  end
  
  def current_node
    @stack_of_open_elements[-1]
  end
  
  def head_elem_pointer
    @head_elem_pointer
  end
  def set_head_elem_pointer( elem )
    @head_elem_pointer = elem
  end
  
  # 終了処理
  def stop_parsing()
    # TODO: 8.2.6 The end
    while pop_current_node_off_stack_of_open_elems() do end
  end
  
  # create an element for a token
  # When the steps below require the UA to create an element for a token in a particular namespace, 
  # the UA must create a node implementing the interface appropriate for the element type corresponding 
  # to the tag name of the token in the given namespace (as given in the specification that defines 
  # that element, e.g. for an a element in the HTML namespace, this specification defines it to be the 
  # HTMLAnchorElement interface), with the tag name being the name of that element, with the node being 
  # in the given namespace, and with the attributes on the node being those given in the given token.
  def create_elem_for_token( token, ns )
    elem = @doc.create_element_ns( ns, token.tag_name )
    # TODO : attributes...
    return elem
  end
  
  # insert an HTML element for a token
  # When the steps below require the UA to insert an HTML element for a token, 
  # the UA must first create an element for the token in the HTML namespace, 
  # and then append this node to the current node, and push it onto the stack of 
  # open elements so that it is the new current node.
  def insert_html_elem_for_token( token )
    elem = create_elem_for_token( token, HTML_NS )
    current_node.append_child( elem )
    push_elem_in_stack_of_open_elems( elem )
    return elem
  end
  
  # Process the token using the rules for the "in body" insertion mode.
  def proc_token_using_rule_for_im( token, insertion_mode )
    handler = method HANDLER_NAMES[ insertion_mode ]
    handler.call( token )
  end
  
  HANDLER_NAMES = []
  def change_insertion_mode( insertion_mode )
    @insertion_mode  = insertion_mode
    @current_handler = method HANDLER_NAMES[ insertion_mode ]
  end
  
  HANDLER_NAMES[ IM_INITIAL ] = :h_im_initial
  def h_im_initial( token )
    case token.type
    when Token::COMMENT_TYPE
      raise NotImplementedError.new()
    when Token::DOCTYPE_TYPE
      raise NotImplementedError.new()
    else
      if token.type == Token::CHARACTER_TYPE and 
            [ "\u0009", "\u000A", "\u000C", "\u000D", "\u0020" ].include? token.data
        # do nothing
      else
        # TODO:
        # If the document is not an iframe srcdoc document, then this is a parse error; set the Document to quirks mode.
        change_insertion_mode IM_BEFORE_HTML
        handle_token( token )
      end
    end
  end
  
  HANDLER_NAMES[ IM_BEFORE_HTML ] = :h_im_before_html
  def h_im_before_html( token )
    case token.type
    when Token::DOCTYPE_TYPE
      # TODO: parse error
      # ignore the token
    when Token::COMMENT_TYPE
      # Append a Comment node to the Document object with the data attribute set to 
      # the data given in the comment token.
      @doc.append_child( @doc.create_comment_node( token.data ) )
    else 
      if token.type == Token::CHARACTER_TYPE and [ "\u0009", "\u000A", "\u000C", "\u000D", "\u0020" ].include? token.data
        # Ignore the token.
      elsif token.type == Token::START_TAG_TYPE and token.tag_name == 'html'
        # Create an element for the token in the HTML namespace.
        # Append it to the Document object. Put this element in the stack of open elements.
        elem = create_elem_for_token( token, HTML_NS )
        @doc.append_child( elem )
        push_elem_in_stack_of_open_elems( elem )
        
        # TODO: 
        # If the Document is being loaded as part of navigation of a browsing context, 
        # then: if the newly created element has a manifest attribute whose value is not the empty string, 
        # then resolve the value of that attribute to an absolute URL, relative to the newly created element, 
        # and if that is successful, run the application cache selection algorithm with the resulting absolute URL 
        # with any <fragment> component removed; 
        # otherwise, if there is no such attribute, or its value is the empty string, or resolving its value fails, 
        # run the application cache selection algorithm with no manifest. The algorithm must be passed the Document object.
        
        # Switch the insertion mode to "before head".
        change_insertion_mode IM_BEFORE_HEAD
      elsif token.type == Token::END_TAG_TYPE && !( [ 'head', 'body', 'html', 'br' ].include? token.tag_name )# Any other end tag
        # TODO: Parse error. 
        # Ignore the token.
      else
        # token.type == Token::END_TAG && [ 'head', 'body', 'html', 'br' ].include? token.tag_name
        # and Anything else
        
        # Create an html element. Append it to the Document object. Put this element in the stack of open elements.
        elem = @doc.create_element_ns( HTML_NS, 'html' )
        @doc.append_child( elem )
        push_elem_in_stack_of_open_elems( elem )
        
        # TODO: 
        # If the Document is being loaded as part of navigation of a browsing context, 
        # then: run the application cache selection algorithm with no manifest, passing it the Document object.
        
        # Switch the insertion mode to "before head", then reprocess the current token.
        change_insertion_mode IM_BEFORE_HEAD
        handle_token( token )
      end
    end
    # The root element can end up being removed from the Document object, e.g. by scripts; nothing in particular happens in such cases, content continues being appended to the nodes as described in the next section.
  end
  
  HANDLER_NAMES[ IM_BEFORE_HEAD ] = :h_im_before_head
  def h_im_before_head( token )
    case token.type
    when Token::COMMENT_TYPE
      #Append a Comment node to the current node with the data attribute set to the data given in the comment token.
      raise NotImplementedError.new()
    when Token::DOCTYPE_TYPE
      # TODO: Parse error. 
      # Ignore the token.
    else
      if token.type == Token::CHARACTER_TYPE and [ "\u0009", "\u000A", "\u000C", "\u000D", "\u0020" ].include? token.data
        # Ignore the token.
      elsif token.type == Token::START_TAG_TYPE and token.tag_name == 'html'
        # Process the token using the rules for the "in body" insertion mode.
        proc_token_using_rule_for_im( token, IM_IN_BODY )
      elsif token.type == Token::START_TAG_TYPE and token.tag_name == 'head'
        # Insert an HTML element for the token.
        elem = insert_html_elem_for_token( token )
        # Set the head element pointer to the newly created head element.
        set_head_elem_pointer( elem )
        # Switch the insertion mode to "in head".
        change_insertion_mode IM_IN_HEAD
      elsif token.type == Token::END_TAG_TYPE and [ 'head', 'body', 'html', 'br' ].include? token.tag_name
        raise NotImplementedError.new()
        # Act as if a start tag token with the tag name "head" and no attributes had been seen, then reprocess the current token.
      elsif token.type == Token::END_TAG_TYPE # Any other end tag
        # TODO: Parse error. 
        # Ignore the token.
      else # Anything else
        # Act as if a start tag token with the tag name "head" and no attributes had been seen, 
        handle_token( Token::StartTag.new( 'head' ) )
        # then reprocess the current token.
        handle_token( token )
      end
    end
  end
  
  HANDLER_NAMES[ IM_IN_HEAD ] = :h_im_in_head
  def h_im_in_head( token )
    case token.type
    when Token::COMMENT_TYPE
      # Append a Comment node to the current node with the data attribute set to the data given in the comment token.
      raise NotImplementedError.new()
    when Token::DOCTYPE_TYPE
      # TODO: Parse error.
      # Ignore the token.
    else
      if token.type == Token::CHARACTER_TYPE and [ "\u0009", "\u000A", "\u000C", "\u000D", "\u0020" ].include? token.data
        # Insert the character into the current node.
        raise NotImplementedError.new()
      elsif token.type == Token::START_TAG_TYPE and token.tag_name == 'html'
        # Process the token using the rules for the "in body" insertion mode.
        raise NotImplementedError.new()
      elsif token.type == Token::START_TAG_TYPE and [ 'base', 'basefont', 'bgsound', 'command', 'link' ].include? token.tag_name
        # Insert an HTML element for the token. Immediately pop the current node off the stack of open elements.
        # Acknowledge the token's self-closing flag, if it is set.
        raise NotImplementedError.new()
      elsif token.type == Token::START_TAG_TYPE and token.tag_name = 'meta'
        # Insert an HTML element for the token. Immediately pop the current node off the stack of open elements.
        # Acknowledge the token's self-closing flag, if it is set.
        # If the element has a charset attribute, and its value is either a supported ASCII-compatible character encoding or a UTF-16 encoding, and the confidence is currently tentative, then change the encoding to the encoding given by the value of the charset attribute.
        # Otherwise, if the element has an http-equiv attribute whose value is an ASCII case-insensitive match for the string "Content-Type", and the element has a content attribute, and applying the algorithm for extracting an encoding from a meta element to that attribute's value returns a supported ASCII-compatible character encoding or a UTF-16 encoding, and the confidence is currently tentative, then change the encoding to the extracted encoding.
        raise NotImplementedError.new()
      elsif token.type == Token::START_TAG_TYPE and token.tag_name == 'title'
        # Follow the generic RCDATA element parsing algorithm.
        raise NotImplementedError.new()
      elsif token.type == Token::START_TAG_TYPE and token.tag_name == 'noscript' and scripting_flag == false
        # Insert an HTML element for the token.
        # Switch the insertion mode to "in head noscript".
        raise NotImplementedError.new()
      elsif token.type == Token::START_TAG_TYPE and [ 'noscript', 'noframes', 'style' ].include? token.tag_name
        # Follow the generic raw text element parsing algorithm.
        raise NotImplementedError.new()
      elsif token.type == Token::START_TAG_TYPE and token.tag_name == 'script'
        # Run these steps:
          # Create an element for the token in the HTML namespace.
          # Mark the element as being "parser-inserted" and unset the element's "force-async" flag.
          # Note: This ensures that, if the script is external, any document.write() calls in the script will execute in-line, instead of blowing the document away, as would happen in most other cases. It also prevents the script from executing until the end tag is seen.
          # If the parser was originally created for the HTML fragment parsing algorithm, then mark the script element as "already started". (fragment case)
          # Append the new element to the current node and push it onto the stack of open elements.
          # Switch the tokenizer to the script data state.
          # Let the original insertion mode be the current insertion mode.
          # Switch the insertion mode to "text".
        raise NotImplementedError.new()
      elsif token.type == Token::END_TAG_TYPE and token.tag_name == 'head'
        # Pop the current node (which will be the head element) off the stack of open elements.
        pop_current_node_off_stack_of_open_elems()
        # Switch the insertion mode to "after head".
        change_insertion_mode IM_AFTER_HEAD
      elsif token.type == Token::END_TAG_TYPE and [ 'body', 'html', 'br' ].include? token.tag_name
        # Act as described in the "anything else" entry below.
        raise NotImplementedError.new()
      elsif token.type == Token::END_TAG_TYPE or token.type == Token::START_TAG_TYPE and token.tag_name == 'head'
        # TODO: Parse error.
        # Ignore the token.
      else # Anything else
        # Act as if an end tag token with the tag name "head" had been seen,
        handle_token( Token::EndTag.new( 'head' ) )
        # and reprocess the current token.
        handle_token( token )
      end
    end
  end
  
  HANDLER_NAMES[ IM_AFTER_HEAD ] = :h_im_after_head
  def h_im_after_head( token )
    case token.type
    when Token::COMMENT_TYPE
      # Append a Comment node to the current node with the data attribute set to the data given in the comment token.
      raise NotImplementedError.new()
    when Token::DOCTYPE_TYPE
      # TODO: Parse error.
      # Ignore the token.
    else
      if token.type == Token::CHARACTER_TYPE and [ "\u0009", "\u000A", "\u000C", "\u000D", "\u0020" ].include? token.data
        # Insert the character into the current node.
        raise NotImplementedError.new()
      elsif token.type == Token::START_TAG_TYPE and token.tag_name == 'html'
        # Process the token using the rules for the "in body" insertion mode.
        raise NotImplementedError.new()
      elsif token.type == Token::START_TAG_TYPE and token.tag_name == 'body'
        #Insert an HTML element for the token.
        insert_html_elem_for_token( token )
        # TODO: 
        #Set the frameset-ok flag to "not ok".
        #Switch the insertion mode to "in body".
        change_insertion_mode IM_IN_BODY
      elsif token.type == Token::START_TAG_TYPE and token.tag_name == 'frameset'
        #Insert an HTML element for the token.
        #Switch the insertion mode to "in frameset".
        raise NotImplementedError.new()
      elsif token.type == Token::START_TAG_TYPE and 
            [ "base", "basefont", "bgsound", "link", "meta", "noframes", "script", "style", "title" ].include? token.tag_name
        # TODO: Parse error.
        #Push the node pointed to by the head element pointer onto the stack of open elements.
        #Process the token using the rules for the "in head" insertion mode.
        #Remove the node pointed to by the head element pointer from the stack of open elements.
        #Note: The head element pointer cannot be null at this point.
        raise NotImplementedError.new()
      elsif ( token.type == Token::END_TAG_TYPE and not [ 'body', 'html', 'br' ].include? token.tag_name ) or 
            ( token.type == Token::START_TAG_TYPE and token.tag_name == 'head' )
        # TODO: Parse error.
        # Ignore the token.
      else # Anything else
        # Act as if a start tag token with the tag name "body" and no attributes had been seen, 
        handle_token( Token::StartTag.new( 'body' ) )
        # TODO:
        # then set the frameset-ok flag back to "ok",
        # and then reprocess the current token.
        handle_token( token )
      end
    end
  end
  
  HANDLER_NAMES[ IM_IN_BODY ] = :h_im_in_body
  def h_im_in_body( token )
    if token.type == Token::EOF_TYPE
      # TODO: 
      # If there is a node in the stack of open elements that is not either a dd element, 
      # a dt element, an li element, a p element, a tbody element, a td element, a tfoot element, 
      # a th element, a thead element, a tr element, the body element, or the html element, 
      # then this is a parse error.
      # Stop parsing.
      raise StopParsing.new()
    else
      raise NotImplementedError.new()
    end
  end
  
end
end
