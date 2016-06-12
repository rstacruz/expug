defmodule Expug.TokenizerTools do
  @moduledoc """
  For tokenizers.

      def tokenizer(source)
        run_tokenizer(source, &(document(&1))
      end

      def document(state)
        eat state, ~r/.../, &(&1 ++ [{&3, :document, &2}])
      end
  """
  def run_tokenizer(source, fun) do
    state = {[], source, 0}
    state = fun.(state)
    {doc, _, position} = state

    # Guard against unexpected end-of-file
    if String.slice(source, position..-1) != "" do
      expected = Enum.uniq_by(get_parse_errors(doc), &(&1))
      {:error, [source: source, position: position, expected: expected]}
    else
      doc = scrub_parse_errors(doc)
      {:ok, doc}
    end
  end

  def get_parse_errors([{_, :parse_error, expected} | rest]) do
    expected ++ get_parse_errors(rest)
  end

  def get_parse_errors(_) do
    []
  end

  def scrub_parse_errors(doc) do
    Enum.reject doc, fn {_, type, _} ->
      type == :parse_error
    end
  end

  @doc """
  Tries one of the following.

      state |> one_of([ &brackets/1, &braces/1, &parens/1 ])
  """
  def one_of(state, funs, expected \\ [])
  def one_of(state, [fun | rest], expected) do
    try do
      fun.(state)
    catch {:parse_error, _, expected_} ->
      one_of(state, rest, expected ++ expected_)
    end
  end

  def one_of({_, pos, _}, [], expected) do
    throw {:parse_error, pos, expected}
  end

  @doc """
  An optional argument.

      state |> optional(&text/1)
  """
  def optional(state, fun) do
    try do
      fun.(state)
    catch
      {:parse_error, _, [nil | _]} ->
        # These are eat_string errors, don't bother with it
        state

      {:parse_error, err_pos, expected} ->
        # Add a parse error pseudo-token to the document. They will be scrubbed
        # later on, but it will be inspected in case of a parse error.
        {doc, source, pos} = state
        {[{err_pos, :parse_error, expected} | doc], source, pos}
    end
  end

  @doc """
  Checks many of a certain token.
  """
  def many_of(state, head) do
    many_of(state, head, head)
  end

  def many_of(state = {_doc, source, pos}, head, tail) do
    if String.slice(source, pos..-1) == "" do
      state
    else
      try do
        state |> head.() |> many_of(head, tail)
      catch {:parse_error, _, _} ->
        state |> tail.()
      end
    end
  end

  @doc """
  Eats a token.

  * `state` - assumed to be `{doc, source, pos}` (given by `run_tokenizer/2`).
  * `expr` - regexp expression.
  * `token_name` (atom, optional) - token name.
  * `reducer` (function, optional) - a function.

  Returns `{ doc, source, pos }` too, where `doc` is transformed via `fun`.

      eat state, ~r/.../, :document
      eat state, ~r/.../, :document, nil  # discard it
      eat state, ~r/.../, :document, &[{&3, :document, &2} | &1]

      # &1 == current state
      # &2 == matched String
      # &3 == position
  """
  def eat(state, expr) do
    eat(state, expr, nil, fn doc, _, _ -> doc end)
  end

  def eat(state, expr, token_name) do
    eat(state, expr, token_name, &([{&3, token_name, &2} | &1]))
  end

  def eat(state, expr, token_name, nil) do
    eat state, expr, token_name, fn state, _, _ -> state end
  end

  def eat({doc, source, pos}, expr, token_name, fun) do
    remainder = String.slice(source, pos..-1)
    case match(expr, remainder) do
      [term] ->
        length = String.length(term)
        { fun.(doc, term, pos), source, pos + length }
      nil ->
        throw {:parse_error, pos, [token_name]}
    end
  end

  def match(expr, remainder) do
    Regex.run(expr, remainder)
  end
end
