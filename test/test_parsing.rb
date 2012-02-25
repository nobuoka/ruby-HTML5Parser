# coding: UTF-8

require 'stringio'
require 'test/unit'
require 'vcdom'

require 'html5_parser'

class TestParsing < Test::Unit::TestCase
  
  # 空文字列 (最初が EOF) をパースするテスト
  def test_of_parsing_empty_string()
    parser = HTML5Parser.new()
    
    doc = VCDOM.create_document( nil, nil, nil )
    parser.parse( doc, StringIO.new( '' ) )
    
    # html, head, body の各要素が存在することとその子ノード数の確認
    root_elem = doc.document_element
    assert_equal( 'html', root_elem.node_name                              )
    assert_equal( 2,      root_elem.child_nodes.length                     )
    assert_equal( 'head', root_elem.child_nodes.item(0).node_name          )
    assert_equal( 0,      root_elem.child_nodes.item(0).child_nodes.length )
    assert_equal( 'body', root_elem.child_nodes.item(1).node_name          )
    assert_equal( 0,      root_elem.child_nodes.item(1).child_nodes.length )
  end
  
  # '<!DOCTYPE html>' をパースするテスト
  def test_of_parsing_only_doctype_string()
    parser = HTML5Parser.new()
    
    doc = VCDOM.create_document( nil, nil, nil )
    parser.parse( doc, StringIO.new( '<!DOCTYPE html>' ) )
    
    # DocumentType ノードについての試験
    doctype = doc.doctype
    assert_equal( doc.class::DOCUMENT_TYPE_NODE, doctype.node_type )
    
    # html, head, body の各要素が存在することとその子ノード数の確認
    root_elem = doc.document_element
    assert_equal( 'html', root_elem.node_name                              )
    assert_equal( 2,      root_elem.child_nodes.length                     )
    assert_equal( 'head', root_elem.child_nodes.item(0).node_name          )
    assert_equal( 0,      root_elem.child_nodes.item(0).child_nodes.length )
    assert_equal( 'body', root_elem.child_nodes.item(1).node_name          )
    assert_equal( 0,      root_elem.child_nodes.item(1).child_nodes.length )
  end
  
end
