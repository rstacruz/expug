defmodule Exslim.Tokenizer do
  @moduledoc """
  ...
  """

  import Regex, only: [run: 3]
  import String, only: [slice: 2]

  @doc """
  Tokenizes a string
  """
  def tokenize(str) do
    doc = []
    result = element({doc, str})
    {doc, str} = result
    doc
  end

  def element(state) do
    state
    |> element_name()
    |> optional fn state -> state
      |> whitespace()
      |> text()
    end
  end

  def optional(state, fun) do
    try do
      fun.(state)
    rescue ParseError -> state
    end
  end

  def one_of(state, funs) do
    die = fn _ -> raise ParseError end
    Enum.reduce funs ++ [die], state, fn fun, acc ->
      try do
        acc || fun.(state)
      rescue ParseError -> nil
      end
    end
  end

  def whitespace(state) do
    eat(state, ~r/[\s\t]+/)
  end

  def buffered_text(state) do
    eat(state, ~r/=/, fn _ -> {:buffered_text} end)
  end

  def text(state) do
    eat(state, ~r/[^\n$]+/, &[{:text, &1}])
  end

  def element_name(state) do
    eat(state, ~r/[a-z]+/, &[{:element_name, &1}])
  end

  def eat({doc, str}, expr, fun \\ fn _ -> [] end) do
    try do
      [term] = Regex.run(expr, str)
      { doc ++ fun.(term), slice(str, String.length(term)..-1) }
    rescue
      MatchError -> raise ParseError, message: "parse error"
    end
  end

  defp lol do
    [
      {:element, "head"},
      {:indent},
      {:element, "title"},
      {:attributes_open},
      {:attribute_key, "lang"},
      {:attribute_value, "en"},
      {:attributes_close},
      {:text, "Hello world"},
      {:outdent}
    ]
  end
end
