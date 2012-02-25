# coding: UTF-8

require 'html5_parser/tokenizer'
require 'html5_parser/tree_constructor'

# http://dev.w3.org/html5/spec/Overview.html#insert-an-html-element
class HTML5Parser
  
  class StopParsing < StandardError
  end
  
  def initialize()
    @tree_constructor = HTML5Parser::TreeConstructor.new( self )
    @tokenizer = HTML5Parser::Tokenizer.new( @tree_constructor )
    # script nesting level, which must be initially set to zero, 
    @script_nesting_level = 0
    # and a parser pause flag, which must be initially set to false
    @parser_pause_flag = false
  end
  
  def parse( document, input_stream )
    doc = document
    @tree_constructor.set_document( doc )
    @tokenizer.set_input_stream( input_stream )
    @tokenizer.start()
    return doc
  end
  
end
