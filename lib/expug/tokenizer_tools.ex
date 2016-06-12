defmodule Expug.TokenizerTools do
  @moduledoc """
  For tokenizers.

      def tokenizer(source)
        {[], source, 0}
        |> document()
        |> finalize()
      end

      def document(state)
        state
        |> eat(~r/^doctype /, :doctype)  # create a token
        |> eat(~r/.../, &([{&3, :document, &2} | &1]))  # create it yourself
      end
  """

  @doc """
  Turns a state tuple (`{doc, source, position}`) into a final result.
  Returns either `{:ok, doc}` or `{:error, [source: _, position: _, expected: _]}`.
  Guards against unexpected end-of-file.
  """
  def finalize({doc, source, position}) do
    if String.slice(source, position..-1) != "" do
      expected = Enum.uniq_by(get_parse_errors(doc), &(&1))
      {:error, [source: source, position: position, expected: expected]}
    else
      doc = scrub_parse_errors(doc)
      {:ok, doc}
    end
  end

  @doc """
  Extracts the last parse errors that happened.

  In case of failure, `run_tokenizer()` will check the last parse errors
  that happened. Returns a list of atoms of the expected tokens.
  """
  def get_parse_errors([{_, :parse_error, expected} | rest]) do
    expected ++ get_parse_errors(rest)
  end

  def get_parse_errors(_) do
    []
  end

  @doc """
  Gets rid of the `:parse_error` hints in the document.
  """
  def scrub_parse_errors(doc) do
    Enum.reject doc, fn {_, type, _} ->
      type == :parse_error
    end
  end

  @doc """
  Finds any one of the given token-eater functions.

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

  @doc """
  Creates an token with a given `token_name`.
  This is functionally the same as `|> eat(~r//, :token_name)`, but using
  `start_empty()` can make your code more readable.

      state
      |> start_empty(:quoted_string)
      |> eat_string(~r/^"/)
      |> eat_string(~r/[^"]+/)
      |> eat_string(~r/^"/)
  """
  def start_empty({doc, str, pos}, token_name) do
    token = {pos, token_name, ""}
    {[token | doc], str, pos}
  end

  @doc """
  Like eat(), but instead of creating a token, it appends to the last token.
  Useful alongside `start_empty()`.

      state
      |> start_empty(:quoted_string)
      |> eat_string(~r/^"/)
      |> eat_string(~r/[^"]+/)
      |> eat_string(~r/^"/)
  """
  def eat_string(state, expr) do
    # parse_error will trip here; the `nil` token name ensures parse errors
    # will not make it to the document.
    state
    |> eat(expr, nil, fn [ {pos, token_name, left} | rest ], right, _pos ->
      [ {pos, token_name, left <> right} | rest ]
    end)
  end
end

