defmodule Exslim.TokenizerTools do
  @moduledoc """
  ...
  """

  alias Exslim.ParseError

  def one_of(state, funs) do
    { _, _, pos } = state
    die = fn _ -> raise ParseError, position: pos end
    Enum.reduce funs ++ [die], state, fn fun, acc ->
      try do
        acc || fun.(state)
      rescue ParseError -> nil
      end
    end
  end

  def optional(state, fun) do
    try do
      fun.(state)
    rescue ParseError -> state
    end
  end

  def eat({doc, str, pos}, expr, fun \\ fn s, _, _ -> s end) do
    remainder = String.slice(str, pos..-1)
    try do
      [term] = Regex.run(expr, remainder)
      length = String.length(term)
      { fun.(doc, term, pos), str, pos + length }
    rescue
      MatchError -> raise ParseError, position: pos
    end
  end
end
