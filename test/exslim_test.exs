defmodule ExslimTest do
  use ExUnit.Case
  doctest Exslim

  test "build" do
    {:ok, eex} = Exslim.to_eex("doctype html\ndiv Hello")
    assert eex == "<!doctype html><div>Hello</div>"
  end

  test "with buffered text" do
    {:ok, eex} = Exslim.to_eex("div= hola()")
    assert eex == "<div><%= hola() %></div>"
  end
end
