defmodule ExpugTest do
  use ExUnit.Case
  doctest Expug

  # test "build" do
  #   {:ok, eex} = Expug.to_eex("doctype html\ndiv Hello")
  #   assert eex == "<!doctype html>\n<div>\nHello\n</div>\n"
  # end

  test "with class" do
    {:ok, eex} = Expug.to_eex("div.hello")
    output = EEx.eval_string(eex)
    assert output == "<div class=\"hello\">\n</div>\n"
  end

  test "with buffered text" do
    {:ok, eex} = Expug.to_eex("div.hello.world")
    output = EEx.eval_string(eex)
    assert output == "<div class=\"hello world\">\n</div>\n"
  end

  test "with assigns in attribute" do
    {:ok, eex} = Expug.to_eex("div(class=@klass)")
    output = EEx.eval_string(eex, assigns: [klass: "hello"])
    assert output == "<div class=\"hello\">\n</div>\n"
  end

  test "with assigns in text" do
    {:ok, eex} = Expug.to_eex("div\n  = @msg")
    output = EEx.eval_string(eex, assigns: [msg: "hello"])
    assert output == "<div>\nhello\n</div>\n"
  end

  test "parse error" do
    {:error, output} = Expug.to_eex("hello\nhuh?")
    assert output == [
      type: :parse_error,
      position: {2, 4},
      expected: [:eq, :whitespace, :attribute_open]
    ]
  end
end
