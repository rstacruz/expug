defmodule Exslim.Tokenizer do
  @moduledoc """
  ...
  """

  @doc """
  Tokenizes a string
  """
  def tokenize(str) do
    doc = []
    result = element({doc, str})
    {doc, str} = result
    if str != "" do
      raise ParseError, message: "Premature end of file: '#{str}'"
    end
    doc
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
    eat(state, ~r/^[\s\t]+/)
  end

  def buffered_text(state) do
    eat state, ~r/^=/, fn state, _ -> state ++ [{:buffered_text}] end
  end

  def text(state) do
    eat state, ~r/^[^\n$]+/, &(&1 ++ [{:text, &2}])
  end

  def element_name(state) do
    eat state, ~r/^[a-z]+/, &(&1 ++ [{:element_name, &2}])
  end

  def eat({doc, str}, expr, fun \\ fn s, _ -> s end) do
    try do
      [term] = Regex.run(expr, str)
      { fun.(doc, term), String.slice(str, String.length(term)..-1) }
    rescue
      MatchError -> raise ParseError, message: "parse error", remaining: str
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
