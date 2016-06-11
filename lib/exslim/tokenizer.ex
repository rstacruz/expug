defmodule Exslim.Tokenizer do
  @moduledoc """
  Tokenizer
  """

  import Exslim.TokenizerTools

  @doc """
  Tokenizes a string.
  Returns a list of tokens. Each token is in the format `{position, token, value}`.

      tokenize("title= name")
      => [
        {0, :element_name, "title"},
        {5, :buffered_text},
        {7, :text, "name"}
      ]
  """
  def tokenize(str) do
    run_tokenizer str, &(elements(&1))
  end

  def elements(state) do
    state
    |> element()
  end

  def element(state) do
    state
    |> element_name()
    |> optional(fn s -> s
      |> optional(fn t -> t
        |> buffered_text()
      end)
      |> whitespace()
      |> text()
    end)
  end

  @doc "Matches whitespace; no tokens emitted"
  def whitespace(state) do
    eat(state, ~r/^[\s\t]+/)
  end

  @doc "Matches `=`"
  def buffered_text(state) do
    eat state, ~r/^=/, fn state, _, pos ->
      state ++ [{pos, :buffered_text, nil}]
    end
  end

  @doc "Matches text"
  def text(state) do
    eat state, ~r/^[^\n$]+/, &(&1 ++ [{&3, :text, &2}])
  end

  @doc "Matches `title` in `title= hello`"
  def element_name(state) do
    eat state, ~r/^[a-z]+/, &(&1 ++ [{&3, :element_name, &2}])
  end
end
