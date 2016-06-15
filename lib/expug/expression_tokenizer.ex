defmodule Expug.ExpressionTokenizer do
  @moduledoc ~S"""
  Tokenizes an expression.
  This is used by `Expug.Tokenizer` to match attribute values and support multiline.

  `expression/2` is used to capture an expression token.

      state
      |> Expug.ExpressionTokenizer.expression(:attribute_value)

  ## Valid expressions
  Expressions are combination of one or more of these:

  - a word without spaces
  - a balanced `(` ... `)` pair (or `[`, or `{`)
  - a string with single quotes `'...'` or double quotes `"..."`

  A balanced pair can have balanced pairs, words, and strings inside them.
  Double-quote strings can have `#{...}` interpolation inside them.

  ## Examples
  These are valid expressions:

      hello
      hello(1 + 2)
      "Hello world"           # strings
      (hello world)           # balanced (...) pair

  These aren't:

      hello world             # spaces
      hello(world[)           # pairs not balanced
      "hello #{foo(}"         # not balanced inside an interpolation
  """

  import Expug.TokenizerTools

  def expression(state, token_name) do
    state
    |> start_empty(token_name)
    |> many_of(&expression_fragment/1)
  end

  def expression_fragment(state) do
    state
    |> one_of([
      &balanced_parentheses/1,
      &balanced_braces/1,
      &balanced_brackets/1,
      &double_quote_string/1,
      &single_quote_string/1,
      &expression_term/1
    ])
  end

  @doc """
  Matches simple expressions like `xyz` or even `a+b`.
  """
  def expression_term(state) do
    state
    |> eat_string(~r/^[^\(\)\[\]\{\}"', ]+/)
  end

  @doc """
  Matches simple expressions like `xyz`, but only for inside parentheses.
  These can have spaces.
  """
  def expression_term_inside(state) do
    state
    |> eat_string(~r/^[^\(\)\[\]\{\}"']+/)
  end

  @doc """
  Matches balanced `(...)` fragments
  """
  def balanced_parentheses(state) do
    state
    |> balanced_pairs(~r/^\(/, ~r/^\)/)
  end

  @doc """
  Matches balanced `{...}` fragments
  """
  def balanced_braces(state) do
    state
    |> balanced_pairs(~r/^\{/, ~r/^\}/)
  end

  @doc """
  Matches balanced `[...]` fragments
  """
  def balanced_brackets(state) do
    state
    |> balanced_pairs(~r/^\[/, ~r/^\]/)
  end

  @doc """
  Underlying implementation for `balanced_*` functions
  """
  def balanced_pairs(state, left, right) do
    state
    |> eat_string(left)
    |> optional(fn s -> s
      |> many_of(fn s -> s
        |> one_of([
          &expression_fragment/1,
          &expression_term_inside/1
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
    |> optional_many_of(fn s -> s
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
    |> optional_many_of(&(&1 |> eat_string(~r/^(?:(?:\\')|[^'])/)))
    |> eat_string(~r/^'/)
  end
end
