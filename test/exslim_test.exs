defmodule ExpugTest do
  use ExUnit.Case
  doctest Expug

  test "build" do
    {:ok, eex} = Expug.to_eex("doctype html\ndiv Hello")
    assert eex == "<!doctype html><div>Hello</div>"
  end

  test "with buffered text" do
    {:ok, eex} = Expug.to_eex("div= hola()")
    assert eex == "<div><%= hola() %></div>"
  end
end
