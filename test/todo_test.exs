defmodule TodoTestd do
  use ExUnit.Case
  @moduletag :pending

  # test "Most everything"
  # test "Track line/column in tokens"
  # test "comma-delimited attributes"
  # test "Multiline attributes"
  # test "HTML escaping"

  # Priority:
  test "Auto-end of `cond do` etc"
  test "value-less attributes (`textarea(spellcheck)`)"
  test "boolean value (`textarea(spellcheck=@spellcheck)`)"
  test "`.` raw text (like `script.`)"
  test "!= unescaped code"

  # Lower priority:
  test "Showing HTML comments with //"
  test "Nesting HTML comments"
end
