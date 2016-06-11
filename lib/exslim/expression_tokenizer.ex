defmodule Exslim.ExpressionTokenizer do
  @moduledoc """
  Tokenizes an expression.
  """

  import Exslim.TokenizerTools

  def expression(state, token_name) do
    state
    |> eat_into(token_name, &double_quote_string/1)
  end

  def double_quote_string(s_state) do
    s_state
    |> eat_string(~r/^"/)
    |> many_of(&(&1 |> eat_string(~r/^[^"]|\\"/)))
    |> eat_string(~r/^"/)
  end

  @doc """
  Consolidates multiple tokens into one token
  """
  def eat_into(state = {doc, str, pos}, token_name, fun) do
    { newdoc, _, new_pos } =
    { "", str, pos } |> fun.()
    { [{pos, token_name, newdoc} | doc], str, new_pos }
  end

  def eat_string(state, expr) do
    state
    |> eat(expr, :_, fn left, right, _ -> left <> right end)
  end
end
