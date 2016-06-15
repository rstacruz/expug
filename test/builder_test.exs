defmodule BuilderTest do
  use ExUnit.Case
  doctest Expug.Builder

  def build(source) do
    {:ok, tokens} = Expug.Tokenizer.tokenize(source)
    {:ok, ast} = Expug.Compiler.compile(tokens)
    Expug.Builder.build(ast)
  end

  test "build" do
    {:ok, eex} = build("doctype html\ndiv Hello")
    assert eex == %{
      :lines => 2,
      1 => ["<!doctype html>"],
      2 => ["<div>", "Hello", "</div>"]
    }
  end

  test "self-closing img" do
    {:ok, eex} = build("doctype html\nimg")
    assert eex == %{
      :lines => 2,
      1 => ["<!doctype html>"],
      2 => ["<img>"]
    }
  end

  test "self-closing xml" do
    {:ok, eex} = build("doctype xml\nimg")
    assert eex == %{
      :lines => 2,
      1 => ["<?xml version=\"1.0\" encoding=\"utf-8\" ?>"],
      2 => ["<img />"]
    }
  end

  test "single element" do
    {:ok, eex} = build("div")
    assert eex == %{
      :lines => 1,
      1 => ["<div></div>"]
    }
  end

  test "single element with attributes" do
    {:ok, eex} = build("div(id=foo)")
    assert eex == %{
      :lines => 1,
      1 => ["<div id=<%= raw(Expug.Runtime.attr_value(foo)) %>></div>"]
    }
  end

  test "with buffered text" do
    {:ok, eex} = build("div= hola()")
    assert eex == %{
      :lines => 1,
      1 =>["<div>", "<%= hola() %>", "</div>"]
    }
  end

  test "nesting" do
    {:ok, eex} = build("""
    doctype html
    div
      span= @hello
    """)
    assert eex == %{
      :lines => 3,
      1 =>["<!doctype html>"],
      2 =>["<div>"],
      3 =>["<span>", "<%= @hello %>", "</span>", "</div>"]
    }
  end

  test "line comments" do
    {:ok, eex} = build("""
    div
    -# hi
    div
    """)
    assert eex == %{
      :lines => 3,
      1 => ["<div></div>"],
      3 => ["<div></div>"]
    }
  end

  test "line comments, capturing" do
    {:ok, eex} = build("""
    div
    -# hi
      h1
    """)
    assert eex == %{
      :lines => 1,
      1 => ["<div></div>"]
    }
  end

  test "line comments, capturing 2" do
    {:ok, eex} = build("""
    div
    -# hi
      h1
    span
    """)
    assert eex == %{
      :lines => 4,
      1 => ["<div></div>"],
      4 => ["<span></span>"]
    }
  end

  test "indentation magic" do
    {:ok, eex} = build("""
    div
      h1
        span
          | Hello
    """)
    assert eex == %{
      :lines => 4,
      1 => ["<div>"],
      2 => ["<h1>"],
      3 => ["<span>"],
      4 => ["Hello", "</span>", "</h1>", "</div>"]
    }
  end

  test "indentation magic 2" do
    {:ok, eex} = build("""
    div
      h1
        span
          | Hello
    div
    """)
    assert eex == %{
      :lines => 5,
      1 => ["<div>"],
      2 => ["<h1>"],
      3 => ["<span>"],
      4 => ["Hello", "</span>", "</h1>", "</div>"],
      5 => ["<div></div>"]
    }
  end

  test "attr and =" do
    {:ok, eex} = build("""
    div(role="main")= @hello
    """)
    assert eex == %{
      :lines => 1,
      1 => [
        "<div role=<%= raw(Expug.Runtime.attr_value(\"main\")) %>>",
        "<%= @hello %>",
        "</div>"
      ]
    }
  end

  test "extra space" do
    {:ok, eex} = build("div\n ")
    assert eex == %{
      :lines => 1,
      1 => [
        "<div></div>"
      ]
    }
  end
end
