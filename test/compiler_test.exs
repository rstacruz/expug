defmodule ExslimCompilerTest do
  use ExUnit.Case

  import Exslim.Tokenizer, only: [tokenize: 1]
  import Exslim.Compiler, only: [compile: 1]

  test "basic" do
    {:ok, tokens} = tokenize("doctype html5")
    {:ok, ast} = compile(tokens)
    assert ast == [doctype: "html5", type: :document]
  end
end
