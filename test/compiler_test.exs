defmodule ExslimCompilerTest do
  use ExUnit.Case

  import Exslim.Tokenizer, only: [tokenize: 1]
  import Exslim.Compiler, only: [compile: 1]

  test "doctype only" do
    {:ok, tokens} = tokenize("doctype html5")
    {:ok, ast} = compile(tokens)
    assert ast == [doctype: "html5", type: :document]
  end

  test "tag only" do
    {:ok, tokens} = tokenize("div")
    {:ok, ast} = compile(tokens)
    assert ast == [
      type: :document,
      children: [
        [name: "div", type: :element]
      ]
    ]
  end

  test "doctype and tag" do
    {:ok, tokens} = tokenize("doctype html5\ndiv")
    {:ok, ast} = compile(tokens)
    assert ast == [
      doctype: "html5",
      type: :document,
      children: [
        [name: "div", type: :element]
      ]
    ]
  end

  test "doctype and tag and id" do
    {:ok, tokens} = tokenize("doctype html5\ndiv#box")
    {:ok, ast} = compile(tokens)
    assert ast == [
      doctype: "html5",
      type: :document,
      children: [
        [id: "box", name: "div", type: :element]
      ]
    ]
  end

  test "tag and classes" do
    {:ok, tokens} = tokenize("div.blue.small")
    {:ok, ast} = compile(tokens)
    assert ast == [
      type: :document,
      children: [
        [name: "div", type: :element, class: ["blue", "small"]]
      ]
    ]
  end

  test "buffered text" do
    {:ok, tokens} = tokenize("div= hello")
    {:ok, ast} = compile(tokens)
    assert ast == [
      type: :document,
      children: [
        [ text: [type: :buffered_text, value: "hello"],
          name: "div", type: :element]
      ]
    ]
  end

  test "doctype and tags" do
    {:ok, tokens} = tokenize("doctype html5\ndiv\nspan")
    {:ok, ast} = compile(tokens)
    assert ast == [
      doctype: "html5",
      type: :document,
      children: [
        [name: "div", type: :element],
        [name: "span", type: :element]
      ]
    ]
  end

  test "nesting" do
    {:ok, tokens} = tokenize("head\n  title")
    {:ok, ast} = compile(tokens)
    assert ast ==
      [ type: :document,
        children:
          [ [ name: "head",
              type: :element,
              children:
                [ [ name: "title", type: :element ] ] ] ] ]
  end

  test "nesting deeper" do
    {:ok, tokens} = tokenize("head\n  title\n    span")
    {:ok, ast} = compile(tokens)
    assert ast ==
      [ type: :document,
        children:
          [ [ name: "head",
              type: :element,
              children:
                [ [ name: "title",
                    type: :element,
                    children:
                      [ [ name: "span", type: :element ] ] ] ] ] ] ]
  end

  test "zigzag nesting" do
    {:ok, tokens} = tokenize("head\n  title\n    span\n  meta")
    {:ok, ast} = compile(tokens)
    assert ast ==
      [ type: :document,
        children:
          [ [ name: "head",
              type: :element,
              children:
                [ [ name: "title",
                    type: :element,
                    children:
                      [ [ name: "span", type: :element ] ] ],
                  [ name: "meta",
                    type: :element ] ] ] ] ]
  end
end
