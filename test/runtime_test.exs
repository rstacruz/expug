defmodule Expug.RuntimeTest do
  use ExUnit.Case
  doctest Expug.Runtime

  import Expug.Runtime

  test "strings" do
    assert attr("value", "hello") == ~S( value="hello")
  end

  test "escaping" do
    assert attr("value", ~S(<h1 a="b">)) == ~S( value="&lt;h1 a=&quot;b&quot;&gt;")
  end

  test "boolean false" do
    assert attr("disabled", false) == ""
  end

  test "boolean true" do
    assert attr("disabled", true) == " disabled"
  end

  test "nil" do
    assert attr("disabled", nil) == ""
  end
end
