defmodule Exslim do
  alias Exslim.Tokenizer

  def to_eex(str) do
    Tokenizer.tokenize(str)
  end
end
