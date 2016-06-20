defmodule Expug.TokenizerTools do
  @moduledoc """
  Builds tokenizers.

      defmodule MyTokenizer do
        import Expug.TokenizerTools

        def tokenizer(source)
          run(source, [], &document/1)
        end

        def document(state)
          state
          |> discard(%r/^doctype /, :doctype_prelude)
          |> eat(%r/^[a-z0-9]+/, :doctype_value)
        end
      end

  ## The state

  `Expug.TokenizerTools.State` is a struct from the `source` and `opts` given to `run/3`.

      %{ tokens: [], source: "...", position: 0, options: ... }

  `run/3` creates the state and invokes a function you give it.

      source = "doctype html"
      run(source, [], &document/1)

  `eat/3` tries to find the given regexp from the `source` at position `pos`.
  If it matches, it returns a new state: a new token is added (`:open_quote` in
  this case), and the position `pos` is advanced.

      eat(state, ~r/^"/, :open_quote)

  If it fails to match, it'll throw a `{:parse_error, pos, [:open_quote]}`.
  Roughly this translates to "parse error in position *pos*, expected to find
  *:open_quote*".

  ## Mixing and matching

  `eat/3` will normally be wrapped into functions for most token types.

      def doctype(state)
        state
        |> discard(%r/^doctype/, :doctype_prelude)
        |> whitespace()
        |> eat(%r/^[a-z0-9]+/, :doctype_value)
      end

      def whitespace(state)
        state
        |> eat(^r/[ \s\t]+, :whitespace, :nil)
      end

  `one_of/3`, `optional/2`, `many_of/2` can then be used to compose these functions.

      state
      |> one_of([ &doctype/1, &foobar/1 ])
      |> optional(&doctype/1)
      |> many_of(&doctype/1)
  """

  alias Expug.TokenizerTools.State

  @doc """
  Turns a State into a final result.

  Returns either `{:ok, doc}` or `{:parse_error, %{type, position, expected}}`.
  Guards against unexpected end-of-file.
  """
  def finalize(%State{tokens: doc, source: source, position: position}) do
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
  def run(source, opts, fun) do
    state = %State{tokens: [], source: source, position: 0, options: opts}
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
  def one_of(%State{} = state, [fun | rest], expected) do
    try do
      fun.(state)
    catch {:parse_error, _, expected_} ->
      one_of(state, rest, expected ++ expected_)
    end
  end

  def one_of(%State{position: pos}, [], expected) do
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
        # These are append errors, don't bother with it
        state

      {:parse_error, err_pos, expected} ->
        # Add a parse error pseudo-token to the document. They will be scrubbed
        # later on, but it will be inspected in case of a parse error.
        next = {err_pos, :parse_error, expected}
        Map.update(state, :tokens, [next], &[next | &1])
    end
  end

  @doc """
  Checks many of a certain token.
  """
  def many_of(state, head) do
    many_of(state, head, head)
  end

  @doc """
  Checks many of a certain token, and lets you provide a different `tail`.
  """
  def many_of(state = %State{source: source, position: pos}, head, tail) do
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
  Checks many of a certain token.
  
  Syntactic sugar for `optional(s, many_of(s, ...))`.
  """
  def optional_many_of(state, head) do
    state
    |> optional(&(&1 |> many_of(head)))
  end

  @doc """
  Consumes a token.

  See `eat/4`.
  """
  def eat(state, expr) do
    eat(state, expr, nil, fn doc, _, _ -> doc end)
  end

  @doc """
  Consumes a token.

      state
      |> eat(~r/[a-z]+/, :key)
      |> discard(~r/\s*=\s*/, :equal)
      |> eat(~r/[a-z]+/, :value)
  """
  def eat(state, expr, token_name) do
    eat(state, expr, token_name, &([{&3, token_name, &2} | &1]))
  end

  @doc """
  Consumes a token, but doesn't push it to the State.

      state
      |> eat(~r/[a-z]+/, :key)
      |> discard(~r/\s*=\s*/, :equal)
      |> eat(~r/[a-z]+/, :value)
  """
  def discard(state, expr, token_name) do
    eat state, expr, token_name, fn state, _, _ -> state end
  end

  @doc """
  Consumes a token.

      eat state, ~r/.../, :document

  Returns a `State`. Available parameters are:

  * `state` - assumed to be a state map (given by `run/3`).
  * `expr` - regexp expression.
  * `token_name` (atom, optional) - token name.
  * `reducer` (function, optional) - a function.

  ## Reducers

  If `reducer` is a function, `tokens` is transformed using that function.

      eat state, ~r/.../, :document, &[{&3, :document, &2} | &1]

      # &1 == tokens in current State
      # &2 == matched String
      # &3 == position

  ## Also see

  `discard/3` will consume a token, but not push it to the State.

      state
      |> discard(~r/\s+/, :whitespace)  # discard it
  """
  def eat(%{tokens: doc, source: source, position: pos} = state, expr, token_name, fun) do
    remainder = String.slice(source, pos..-1)
    case match(expr, remainder) do
      [term] ->
        length = String.length(term)
        state
        |> Map.put(:position, pos + length)
        |> Map.put(:tokens, fun.(doc, term, pos))
      nil ->
        throw {:parse_error, pos, [token_name]}
    end
  end

  @doc """
  Creates an token with a given `token_name`.

  This is functionally the same as `|> eat(~r//, :token_name)`, but using
  `start_empty()` can make your code more readable.

      state
      |> start_empty(:quoted_string)
      |> append(~r/^"/)
      |> append(~r/[^"]+/)
      |> append(~r/^"/)
  """
  def start_empty(%State{position: pos} = state, token_name) do
    token = {pos, token_name, ""}
    state
    |> Map.update(:tokens, [token], &[token | &1])
  end

  @doc """
  Like `eat/4`, but instead of creating a token, it appends to the last token.

  Useful alongside `start_empty()`.

      state
      |> start_empty(:quoted_string)
      |> append(~r/^"/)
      |> append(~r/[^"]+/)
      |> append(~r/^"/)
  """
  def append(state, expr) do
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

  # Converts a position number `n` to a tuple `{line, col}`.
  defp convert_position(pos, offsets) when is_number(pos) do
    line = Enum.find_index(offsets, &(pos < &1))
    offset = Enum.at(offsets, line - 1)
    col = pos - offset
    {line, col + 1}
  end

  defp convert_position({pos, a, b}, offsets) do
    {convert_position(pos, offsets), a, b}
  end

  defp convert_position([ token | rest ], offsets) do
    [ convert_position(token, offsets) | convert_position(rest, offsets) ]
  end

  defp convert_position([], _offsets) do
    []
  end

  defp match(expr, remainder) do
    Regex.run(expr, remainder)
  end
end
