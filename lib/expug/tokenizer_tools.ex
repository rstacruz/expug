defmodule Expug.TokenizerTools do
  @moduledoc """
  For tokenizers.

      def tokenizer(source)
        run(source, [], &document/1)
      end

      def document(state)
        state
        |> eat(~r/^doctype /, :doctype)  # create a token
      end

  ## The state

  The state begins as a tuple of `{[], source, 0}`. This is the list of tokens,
  the source text, and the cursor position (aka, `{doc, source, pos}`).

      eat(state, ~r/^"/, :open_quote)

  The `eat()` function tries to find the given regexp from the `source` at
  position `pos`. If it matches, it returns a new state: a new token is added
  (`:open_quote` in this case), and the position `pos` is advanced.

  If it fails to match, it'll throw a `{:parse_error, pos, [:open_quote]}`.
  Roughly this translates to "parse error in position *pos*, expected to find
  *:open_quote*".

  ## Mixing and matching

  Normally you'd make functions for most token types:

      def doctype(state)
        state
        |> eat(%r/^doctype/, :doctype, nil)
        |> whitespace()
        |> eat(%r/^[a-z0-9]+/, :doctype_value)
      end

  You can then compose these functions using:

      state
      |> one_of([ &doctype/1, &foobar/1 ])
      |> optional(&doctype/1)
      |> many_of(&doctype/1)
  """

  @doc """
  Turns a state tuple (`{doc, source, position}`) into a final result.  Returns
  either `{:ok, doc}` or `{:parse_error, %{type, position, expected}}`.
  Guards against unexpected end-of-file.
  """
  def finalize({doc, source, position}) do
    if String.slice(source, position..-1) != "" do
      expected = Enum.uniq_by(get_parse_errors(doc), &(&1))
      throw {:parse_error, position, expected}
    else
      doc
      |> scrub_parse_errors()
      |> convert_positions(source)
    end
  end

  @doc """
  Runs; catches parse errors and throws them properly.
  """
  def run(source, _opts, fun) do
    state = {[], source, 0}
    try do
      fun.(state)
      |> finalize()
    catch {:parse_error, position, expected} ->
      position = convert_positions(position, source)
      throw %{type: :parse_error, position: position, expected: expected}
    end
  end

  @doc """
  Extracts the last parse errors that happened.

  In case of failure, `run/3` will check the last parse errors
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

  def one_of({_, _, pos}, [], expected) do
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

  def optional_many_of(state, head) do
    state
    |> optional(&(&1 |> many_of(head)))
  end

  @doc """
  Eats a token.

  * `state` - assumed to be `{doc, source, pos}` (given by `run/3`).
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

  @doc ~S"""
  Converts numeric positions into `{line, col}` tuples.

      iex> source = "div\n  body"
      iex> doc = [
      ...>   { 0, :indent, "" },
      ...>   { 0, :element_name, "div" },
      ...>   { 4, :indent, "  " },
      ...>   { 6, :element_name, "body" }
      ...> ]
      iex> Expug.TokenizerTools.convert_positions(doc, source)
      [
        { {1, 1}, :indent, "" },
        { {1, 1}, :element_name, "div" },
        { {2, 1}, :indent, "  " },
        { {2, 3}, :element_name, "body" }
      ]
  """
  def convert_positions(doc, source) do
    offsets = String.split(source, "\n")
      |> Stream.map(&(String.length(&1) + 1))
      |> Stream.scan(&(&1 + &2))
      |> Enum.to_list
    offsets = [ 0 | offsets ]
    convert_position(doc, offsets)
  end

  @doc """
  Converts a position number `n` to a tuple `{line, col}`.
  """

  def convert_position(pos, offsets) when is_number(pos) do
    line = Enum.find_index(offsets, &(pos < &1))
    offset = Enum.at(offsets, line - 1)
    col = pos - offset
    {line, col + 1}
  end

  def convert_position({pos, a, b}, offsets) do
    {convert_position(pos, offsets), a, b}
  end

  def convert_position([ token | rest ], offsets) do
    [ convert_position(token, offsets) | convert_position(rest, offsets) ]
  end

  def convert_position([], _offsets) do
    []
  end
end
