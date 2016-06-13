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
      1 => ["<!doctype html>"],
      2 => ["<div>", "Hello", "</div>"]
    }
  end

  test "with buffered text" do
    {:ok, eex} = build("div= hola()")
    assert eex == %{
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
      1 =>["<!doctype html>"],
      2 =>["<div>"],
      3 =>["<span>", "<%= @hello %>", "</span>", "</div>"]
    }
  end
end
