defmodule Exslim.ExpressionTokenizer do
  @moduledoc """
  Tokenizes an expression.
  """

  import Exslim.TokenizerTools

  def expression(state, token_name) do
    state
    |> put_token(token_name)
    |> one_of([
      &expression_fragment/1,
      &expression_term/1
    ])
  end

  def put_token(state = {doc, str, pos}, token_name) do
    token = {pos, token_name, ""}
    {[token | doc], str, pos}
  end

  def expression_fragment(state) do
    state
    |> one_of([
      &balanced_parentheses/1,
      &balanced_braces/1,
      &balanced_brackets/1,
      &double_quote_string/1,
      &single_quote_string/1
    ])
  end

  @doc """
  Matches simple expressions like `xyz` or even `a+b`.
  The magic of `one_of` here is that so it can eat `a(b + c)d(e + f)`, because the
  balanced parentheses keep the continuity.
  """
  def expression_term(state) do
    state
    |> many_of(fn s -> s
      |> one_of([
        &(&1 |> eat_string(~r/[^\(\)\[\]\{\} ]+/)),
        &expression_fragment/1
      ])
    end)
  end

  @doc """
  Matches balanced `(...)` fragments
  """
  def balanced_parentheses(state) do
    state
    |> balanced_pairs(~r/^\(/, ~r/^\)/, ~r/^[^\(\)]+/)
  end

  @doc """
  Matches balanced `{...}` fragments
  """
  def balanced_braces(state) do
    state
    |> balanced_pairs(~r/^\{/, ~r/^\}/, ~r/^[^\{\}]+/)
  end

  @doc """
  Matches balanced `[...]` fragments
  """
  def balanced_brackets(state) do
    state
    |> balanced_pairs(~r/^\[/, ~r/^\]/, ~r/^[^\[\]]+/)
  end

  @doc """
  Underlying implementation for `balanced_*` functions
  """
  def balanced_pairs(state, left, right, exclusion) do
    state
    |> eat_string(left)
    |> optional(fn s -> s
      |> many_of(fn s -> s
        |> one_of([
          &expression_fragment/1,
          &(&1 |> eat_string(exclusion))
        ])
      end)
    end)
    |> eat_string(right)
  end

  @doc """
  Matches an entire double-quoted string, taking care of interpolation and escaping
  """
  def double_quote_string(state) do
    state
    |> eat_string(~r/^"/)
    |> many_of(fn s -> s
      |> one_of([
        &(&1 |> eat_string(~r/^#/) |> balanced_braces()),
        &(&1 |> eat_string(~r/^(?:(?:\\")|[^"])/))
      ])
    end)
    |> eat_string(~r/^"/)
  end

  @doc """
  Matches an entire double-quoted string, taking care of escaping
  """
  def single_quote_string(state) do
    state
    |> eat_string(~r/^'/)
    |> many_of(&(&1 |> eat_string(~r/^(?:(?:\\')|[^'])/)))
    |> eat_string(~r/^'/)
  end

  @doc """
  Like eat(), but instead of creating a token, it appends to the last token.
  """
  def eat_string(state, expr) do
    state
    |> eat(expr, :_, fn [ {pos, token_name, left} | rest ], right, _pos ->
      [ {pos, token_name, left <> right} | rest ]
    end)
  end
end
