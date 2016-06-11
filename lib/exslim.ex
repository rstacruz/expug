defmodule Exslim do
  alias Exslim.Tokenizer

  def to_eex(str) do
    tokenize(str)
  end

  def tokenize(str) do
    Tokenizer.tokenize(str)
  end
end
