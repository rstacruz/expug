defmodule ExslimTest do
  use ExUnit.Case
  doctest Exslim

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "basic" do
    output = Exslim.to_eex("head")
    assert output == [{:element_name, "head"}]
  end

  test "basic with text" do
    output = Exslim.to_eex("title Hello world")
    assert output == [
      {:element_name, "title"},
      {:text, "Hello world"}
    ]
  end

  test "eex" do
    input = """
    head Hello world
    """

    output = Exslim.to_eex(input)
    IO.puts(inspect(output))
  end
end
