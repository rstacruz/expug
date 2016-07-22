defmodule ExpugTokenizerTest do
  use ExUnit.Case

  import Expug.Tokenizer, only: [tokenize: 1]
  import Enum, only: [reverse: 1]

  doctest Expug.Tokenizer

  test "basic" do
    output = tokenize("head")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "head"}
    ]
  end

  test "h1" do
    output = tokenize("h1")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "h1"}
    ]
  end

  test "extra whitespaces (spaces)" do
    output = tokenize("h1 ")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "h1"}
    ]
  end

  test "extra whitespaces (newline)" do
    output = tokenize("h1\n")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "h1"}
    ]
  end

  test "extra whitespaces (newline and spaces)" do
    output = tokenize("h1  \n  ")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "h1"}
    ]
  end

  test "xml namespace" do
    output = tokenize("html:h1")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "html:h1"}
    ]
  end

  test "dashes" do # but why?
    output = tokenize("Todo-app")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "Todo-app"}
    ]
  end

  test "basic with text" do
    output = tokenize("title Hello world")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "title"},
      {{1, 7}, :raw_text, "Hello world"}
    ]
  end

  test "title= name" do
    output = tokenize("title= name")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "title"},
      {{1, 8}, :buffered_text, "name"}
    ]
  end

  test "| name $200" do
    output = tokenize("| name $200")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :raw_text, "name $200"}
    ]
  end

  test "multiline" do
    output = tokenize("head\nbody\n")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "head"},
      {{2, 1}, :indent, 0},
      {{2, 1}, :element_name, "body"},
    ]
  end

  test "multiline with blank lines" do
    output = tokenize("head\n   \n  \nbody\n")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "head"},
      {{4, 1}, :indent, 0},
      {{4, 1}, :element_name, "body"},
    ]
  end

  test "div[]" do
    output = tokenize("div[]")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "["},
      {{1, 5}, :attribute_close, "]"}
    ]
  end

  test "div()" do
    output = tokenize("div()")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_close, ")"}
    ]
  end

  test "div(id=\"hi\")" do
    output = tokenize("div(id=\"hi\")")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, "\"hi\""},
      {{1, 12}, :attribute_close, ")"}
    ]
  end

  test "div(id='hi')" do
    output = tokenize("div(id='hi')")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, "'hi'"},
      {{1, 12}, :attribute_close, ")"}
    ]
  end

  test ~S[div(id='\'')] do
    output = tokenize(~S[div(id='\'')])
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, ~S['\'']},
      {{1, 12}, :attribute_close, ")"}
    ]
  end

  test ~S[div(id='hi\'')] do
    output = tokenize(~S[div(id='hi\'')])
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, ~S['hi\'']},
      {{1, 14}, :attribute_close, ")"}
    ]
  end

  test "div(id=\"hi\" class=\"foo\")" do
    output = tokenize("div(id=\"hi\" class=\"foo\")")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, "\"hi\""},
      {{1, 13}, :attribute_key, "class"},
      {{1, 19}, :attribute_value, "\"foo\""},
      {{1, 24}, :attribute_close, ")"}
    ]
  end

  test "class" do
    output = tokenize("div.blue")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 5}, :element_class, "blue"}
    ]
  end

  test "classes" do
    output = tokenize("div.blue.sm")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 5}, :element_class, "blue"},
      {{1, 10}, :element_class, "sm"}
    ]
  end

  test "classes and ID" do
    output = tokenize("div.blue.sm#box")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 5}, :element_class, "blue"},
      {{1, 10}, :element_class, "sm"},
      {{1, 13}, :element_id, "box"}
    ]
  end

  test "parse error" do
    try do
      tokenize("hello\nhuh?")
    catch output ->
      assert %{
        type: :parse_error,
        position: {2, 4},
        expected: [:eq, :whitespace, :block_text, :attribute_open]
      } = output
    end
  end

  test "| raw text" do
    output = tokenize("| text")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :raw_text, "text"}
    ]
  end

  test "= buffered text" do
    output = tokenize("= text")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :buffered_text, "text"}
    ]
  end

  test "- statement" do
    output = tokenize("- text")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :statement, "text"}
    ]
  end

  test "- statement multiline" do
    output = tokenize("- text,\n  foo")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :statement, "text,\n  foo"}
    ]
  end

  test "- statement multiline (2)" do
    output = tokenize("- text(\n  foo)\ndiv")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :statement, "text(\n  foo)"},
      {{3, 1}, :indent, 0},
      {{3, 1}, :element_name, "div"}
    ]
  end

  test "doctype" do
    output = tokenize("doctype html5")
    assert reverse(output) == [
      {{1, 9}, :doctype, "html5"}
    ]
  end

  test "doctype + html" do
    output = tokenize("doctype html5\nhtml")
    assert reverse(output) == [
      {{1, 9}, :doctype, "html5"},
      {{2, 1}, :indent, 0},
      {{2, 1}, :element_name, "html"}
    ]
  end

  test "div(id=(hello))" do
    output = tokenize("div(id=(hello))")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, "(hello)"},
      {{1, 15}, :attribute_close, ")"}
    ]
  end

  test "div(id=(hello(world)))" do
    output = tokenize("div(id=(hello(world)))")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, "(hello(world))"},
      {{1, 22}, :attribute_close, ")"}
    ]
  end

  test "div(id=(hello(worl[]d)))" do
    output = tokenize("div(id=(hello(worl[]d)))")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, "(hello(worl[]d))"},
      {{1, 24}, :attribute_close, ")"}
    ]
  end

  test ~S[div(id="hello #{world}")] do
    output = tokenize(~S[div(id="hello #{world}")])
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, ~S["hello #{world}"]},
      {{1, 24}, :attribute_close, ")"}
    ]
  end

  test ~S[div(id=hello)] do
    output = tokenize(~S[div(id=hello)])
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "id"},
      {{1, 8}, :attribute_value, "hello"},
      {{1, 13}, :attribute_close, ")"}
    ]
  end

  test "with indent" do
    output = tokenize("head\n  title")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "head"},
      {{2, 1}, :indent, 2},
      {{2, 3}, :element_name, "title"}
    ]
  end

  test ~S[div(src=a id=b)] do
    output = tokenize(~S[div(src=a id=b)])
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "src"},
      {{1, 9}, :attribute_value, "a"},
      {{1, 11}, :attribute_key, "id"},
      {{1, 14}, :attribute_value, "b"},
      {{1, 15}, :attribute_close, ")"}
    ]
  end

  test ~S[div( src=a id=b )] do
    output = tokenize(~S[div( src=a id=b )])
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 6}, :attribute_key, "src"},
      {{1, 10}, :attribute_value, "a"},
      {{1, 12}, :attribute_key, "id"},
      {{1, 15}, :attribute_value, "b"},
      {{1, 17}, :attribute_close, ")"}
    ]
  end

  test ~S[div(src=a, id=b)] do
    output = tokenize(~S[div(src=a, id=b)])
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "src"},
      {{1, 9}, :attribute_value, "a"},
      {{1, 12}, :attribute_key, "id"},
      {{1, 15}, :attribute_value, "b"},
      {{1, 16}, :attribute_close, ")"}
    ]
  end

  test "newline between attributes" do
    output = tokenize("div(src=a,\n  id=b)")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "src"},
      {{1, 9}, :attribute_value, "a"},
      {{2, 3}, :attribute_key, "id"},
      {{2, 6}, :attribute_value, "b"},
      {{2, 7}, :attribute_close, ")"}
    ]
  end

  test "multiline attribute contents" do
    output = tokenize("div(\n  src=a\n  )")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{2, 3}, :attribute_key, "src"},
      {{2, 7}, :attribute_value, "a"},
      {{3, 3}, :attribute_close, ")"}
    ]
  end

  test "multiline expressions" do
    output = tokenize("div(src=(a\n  b))")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "src"},
      {{1, 9}, :attribute_value, "(a\n  b)"},
      {{2, 5}, :attribute_close, ")"}
    ]
  end

  test "empty attributes" do
    output = tokenize("div(src=\"\")")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "src"},
      {{1, 9}, :attribute_value, "\"\""},
      {{1, 11}, :attribute_close, ")"}
    ]
  end

  test "-# comments" do
    output = tokenize("div\n-# ...")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{2, 1}, :indent, 0},
      {{2, 4}, :line_comment, "..."}
    ]
  end

  test "-# comments, blank" do
    output = tokenize("div\n-#")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{2, 1}, :indent, 0},
      {{2, 3}, :line_comment, ""}
    ]
  end

  test "-# comments, space" do
    output = tokenize("div\n-# ")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{2, 1}, :indent, 0},
      {{2, 3}, :line_comment, ""}
    ]
  end

  test "-# comments, nesting" do
    output = tokenize("-#\n  foobar")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :line_comment, ""},
      {{2, 3}, :subindent, "foobar"}
    ]
  end

  test "-// comments, nesting" do
    output = tokenize("-//\n  foobar")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 4}, :line_comment, ""},
      {{2, 3}, :subindent, "foobar"}
    ]
  end

  test "-# comments, nesting and after" do
    output = tokenize("-#\n  foobar\ndiv")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :line_comment, ""},
      {{2, 3}, :subindent, "foobar"},
      {{3, 1}, :indent, 0},
      {{3, 1}, :element_name, "div"}
    ]
  end

  test "// comments" do
    output = tokenize("div\n// ...")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{2, 1}, :indent, 0},
      {{2, 4}, :html_comment, "..."}
    ]
  end

  test "// comments, nesting" do
    output = tokenize("div\n// ...\n  hi")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{2, 1}, :indent, 0},
      {{2, 4}, :html_comment, "..."},
      {{3, 3}, :subindent, "hi"}
    ]
  end

  test "- with children" do
    output = tokenize("- hi\n  div")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :statement, "hi"},
      {{2, 1}, :indent, 2},
      {{2, 3}, :element_name, "div"}
    ]
  end

  test "= with children" do
    output = tokenize("= hi\n  div")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 3}, :buffered_text, "hi"},
      {{2, 1}, :indent, 2},
      {{2, 3}, :element_name, "div"}
    ]
  end

  test "separating attributes with newlines" do
    output = tokenize("div(a=1\nb=2)")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "a"},
      {{1, 7}, :attribute_value, "1"},
      {{2, 1}, :attribute_key, "b"},
      {{2, 3}, :attribute_value, "2"},
      {{2, 4}, :attribute_close, ")"}
    ]
  end

  test "script." do
    output = tokenize("script.\n  hello")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "script"},
      {{1, 7}, :block_text, "."},
      {{2, 3}, :subindent, "hello"}
    ]
  end

  test "script. with class" do
    output = tokenize("script.box.\n  hello")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "script"},
      {{1, 8}, :element_class, "box"},
      {{1, 11}, :block_text, "."},
      {{2, 3}, :subindent, "hello"}
    ]
  end

  test "script. with class and attributes" do
    output = tokenize("script.box(id=\"foo\").\n  hello")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "script"},
      {{1, 8}, :element_class, "box"},
      {{1, 11}, :attribute_open, "("},
      {{1, 12}, :attribute_key, "id"},
      {{1, 15}, :attribute_value, "\"foo\""},
      {{1, 20}, :attribute_close, ")"},
      {{1, 21}, :block_text, "."},
      {{2, 3}, :subindent, "hello"}
    ]
  end

  test "script. multiline" do
    output = tokenize("script.\n  hello\n    world")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "script"},
      {{1, 7}, :block_text, "."},
      {{2, 3}, :subindent, "hello"},
      {{3, 3}, :subindent, "  world"}
    ]
  end

  test "script. multiline with sibling" do
    output = tokenize("script.\n  hello\n    world\ndiv")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "script"},
      {{1, 7}, :block_text, "."},
      {{2, 3}, :subindent, "hello"},
      {{3, 3}, :subindent, "  world"},
      {{4, 1}, :indent, 0},
      {{4, 1}, :element_name, "div"}
    ]
  end

  test "value-less attributes" do
    output = tokenize("div(src)")
    assert reverse(output) == [
      {{1, 1}, :indent, 0},
      {{1, 1}, :element_name, "div"},
      {{1, 4}, :attribute_open, "("},
      {{1, 5}, :attribute_key, "src"},
      {{1, 8}, :attribute_close, ")"}
    ]
  end

  # test "comma delimited attributes"
  # test "script."
  # test "comments"
  # test "!="
end
