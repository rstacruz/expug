defmodule ExpugTest do
  use ExUnit.Case
  doctest Expug

  # test "build" do
  #   {:ok, eex} = Expug.to_eex("doctype html\ndiv Hello")
  #   assert eex == "<!doctype html>\n<div>\nHello\n</div>\n"
  # end

  test "with class" do
    {:ok, eex} = Expug.to_eex("div.hello")
    output = run_eex(eex)
    assert output == "<div class=\"hello\"></div>\n"
  end

  test "with buffered text" do
    {:ok, eex} = Expug.to_eex("div.hello.world")
    output = run_eex(eex)
    assert output == "<div class=\"hello world\"></div>\n"
  end

  test "with assigns in attribute" do
    {:ok, eex} = Expug.to_eex("div(class=@klass)")
    output = run_eex(eex, assigns: [klass: "hello"])
    assert output == "<div class=\"hello\"></div>\n"
  end

  test "with assigns in text" do
    {:ok, eex} = Expug.to_eex("div\n  = @msg")
    output = run_eex(eex, assigns: [msg: "hello"])
    assert output == "<div>\nhello\n</div>\n"
  end

  test "parse error" do
    {:error, output} = Expug.to_eex("hello\nhuh?")
    assert %{
      type: :parse_error,
      position: {2, 4},
      expected: [:eq, :bang_eq, :whitespace, :block_text, :attribute_open]
    } = output
  end

  test "bang, parse error" do
    msg = """
    Parse error on line 2

        huh?
           ^

    Expug encountered a character it didn't expect.
    Expected one of:

    * eq
    * bang_eq
    * whitespace
    * block_text
    * attribute_open
    """
    assert_raise Expug.Error, msg, fn ->
      Expug.to_eex!("hello\nhuh?")
    end
  end

  # test "bang, compile error" do
  #   msg = "ambiguous indentation on line 4 col 2"
  #   assert_raise Expug.Error, msg, fn ->
  #     Expug.to_eex!("h1\n  h2\n    h3\n h4")
  #   end
  # end

  @doc """
  A terrible hack, I know, but this means we get to skip on Phoenix.HTML as a
  dependency
  """
  def run_eex(eex, opts \\ []) do
    eex
    |> String.replace(~r/raw\(/, "raw.(")
    |> EEx.eval_string([{:raw, fn x -> x end} | opts])
  end
end
