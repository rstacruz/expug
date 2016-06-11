defmodule ExslimTokenizerTest do
  use ExUnit.Case

  test "basic" do
    {:ok, output} = Exslim.to_eex("head")
    assert output == [
      {0, :indent, ""},
      {0, :element_name, "head"}
    ]
  end

  test "basic with text" do
    {:ok, output} = Exslim.to_eex("title Hello world")
    assert output == [
      {0, :indent, ""},
      {0, :element_name, "title"},
      {6, :sole_raw_text, "Hello world"}
    ]
  end

  test "title= name" do
    {:ok, output} = Exslim.to_eex("title= name")
    assert output == [
      {0, :indent, ""},
      {0, :element_name, "title"},
      {7, :sole_buffered_text, "name"}
    ]
  end

  test "multiline" do
    {:ok, output} = Exslim.to_eex("head\nbody\n")
    assert output == [
      {0, :indent, ""},
      {0, :element_name, "head"},
      {5, :indent, ""},
      {5, :element_name, "body"},
    ]
  end

  test "div[]" do
    {:ok, output} = Exslim.to_eex("div[]")
    assert output == [
      {0, :indent, ""},
      {0, :element_name, "div"},
      {3, :attribute_open, "["},
      {4, :attribute_close, "]"}
    ]
  end

  test "div()" do
    {:ok, output} = Exslim.to_eex("div()")
    assert output == [
      {0, :indent, ""},
      {0, :element_name, "div"},
      {3, :attribute_open, "("},
      {4, :attribute_close, ")"}
    ]
  end

  test "div(id=\"hi\")" do
    {:ok, output} = Exslim.to_eex("div(id=\"hi\")")
    assert output == [
      {0, :indent, ""},
      {0, :element_name, "div"},
      {3, :attribute_open, "("},
      {4, :attribute_key, "id"},
      {7, :attribute_value, "\"hi\""},
      {11, :attribute_close, ")"}
    ]
  end

  test "div(id=\"hi\" class=\"foo\")" do
    {:ok, output} = Exslim.to_eex("div(id=\"hi\" class=\"foo\")")
    assert output == [
      {0, :indent, ""},
      {0, :element_name, "div"},
      {3, :attribute_open, "("},
      {4, :attribute_key, "id"},
      {7, :attribute_value, "\"hi\""},
      {12, :attribute_key, "class"},
      {18, :attribute_value, "\"foo\""},
      {23, :attribute_close, ")"}
    ]
  end

  test "class" do
    {:ok, output} = Exslim.to_eex("div.blue")
    assert output == [
      {0, :indent, ""},
      {0, :element_name, "div"},
      {4, :element_class, "blue"}
    ]
  end

  test "classes" do
    {:ok, output} = Exslim.to_eex("div.blue.sm")
    assert output == [
      {0, :indent, ""},
      {0, :element_name, "div"},
      {4, :element_class, "blue"},
      {9, :element_class, "sm"}
    ]
  end

  test "classes and ID" do
    {:ok, output} = Exslim.to_eex("div.blue.sm#box")
    assert output == [
      {0, :indent, ""},
      {0, :element_name, "div"},
      {4, :element_class, "blue"},
      {9, :element_class, "sm"},
      {12, :element_id, "box"}
    ]
  end

  test "parse error" do
    {:error, output} = Exslim.to_eex("huh?")
    assert output == {:parse_error, 3, [:eof]}
  end

  test "| raw text" do
    {:ok, output} = Exslim.to_eex("| text")
    assert output == [
      {0, :indent, ""},
      {2, :raw_text, "text"}
    ]
  end

  test "= buffered text" do
    {:ok, output} = Exslim.to_eex("= text")
    assert output == [
      {0, :indent, ""},
      {2, :buffered_text, "text"}
    ]
  end

  test "- statement" do
    {:ok, output} = Exslim.to_eex("- text")
    assert output == [
      {0, :indent, ""},
      {2, :statement, "text"}
    ]
  end

  # test "doctype"
  # test "true expressions [foo=(a + b)]"
  # test "comma delimited attributes"
  # test "script."
end
