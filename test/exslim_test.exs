defmodule ExpugTest do
  use ExUnit.Case
  doctest Expug

  test "build" do
    {:ok, eex} = Expug.to_eex("doctype html\ndiv Hello")
    assert eex == "<!doctype html>\n<div>\nHello\n</div>\n"
  end

  test "with buffered text" do
    {:ok, eex} = Expug.to_eex("div= hola()")
    assert eex == "<div>\n<%= hola() %>\n</div>\n"
  end

  test "parse error" do
    {:parse_error, output} = Expug.to_eex("hello\nhuh?")
    assert output == [
      source: "hello\nhuh?",
      position: {2, 4},
      expected: [:eq, :whitespace, :attribute_open]
    ]
  end
end
