defmodule ExslimTest do
  use ExUnit.Case
  doctest Exslim

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "basic" do
    {:ok, output} = Exslim.to_eex("head")
    assert output == [
      {0, :element_name, "head"}
    ]
  end

  test "basic with text" do
    {:ok, output} = Exslim.to_eex("title Hello world")
    assert output == [
      {0, :element_name, "title"},
      {6, :text, "Hello world"}
    ]
  end

  test "title= name" do
    {:ok, output} = Exslim.to_eex("title= name")
    assert output == [
      {0, :element_name, "title"},
      {5, :buffered_text, "="},
      {7, :text, "name"}
    ]
  end

  test "multiline" do
    {:ok, output} = Exslim.to_eex("head\nbody\n")
    assert output == [
      {0, :element_name, "head"},
      {5, :element_name, "body"},
    ]
  end

  test "parse error" do
    {:error, output} = Exslim.to_eex("huh?")
    assert output == {:parse_error, 3, [:eof]}
  end
end
