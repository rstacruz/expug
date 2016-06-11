defmodule ExslimTest do
  use ExUnit.Case
  doctest Exslim

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "basic" do
    output = Exslim.to_eex("head")
    assert output == [
      {0, :element_name, "head"}
    ]
  end

  test "basic with text" do
    output = Exslim.to_eex("title Hello world")
    assert output == [
      {0, :element_name, "title"},
      {6, :text, "Hello world"}
    ]
  end

  test "title= name" do
    output = Exslim.to_eex("title= name")
    assert output == [
      {0, :element_name, "title"},
      {5, :buffered_text, nil},
      {7, :text, "name"}
    ]
  end

  test "parse error" do
    output = Exslim.to_eex("! name")
  end
end
