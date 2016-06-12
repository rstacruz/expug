defmodule Exslim.Tokenizer do
  @moduledoc """
  Tokenizes a Slim template into a list of tokens. The main entry point is
  `tokenize/1`.

  Note that the tokens are reversed! It's easier to append to the top of a list
  rather than to the end, making it more efficient.

  ## Token types

  `div.blue#box`

    - `:indent` - (empty string)
    - `:element_name` - `div`
    - `:element_class` - `blue`
    - `:element_id - `box`

  `div(name="en")`

    - :attribute_open` - `(`
    - :attribute_key` - `name`
    - :attribute_value` - `"en"`
    - :attribute_close` - `)`

  `div= hello`

    - `:sole_buffered_text` - `hello`

  `div hello`

    - `:sole_raw_text` - `hello`

  `| Hello there`

    - `:raw_text` - `Hello there`

  `= Hello there`

    - `:buffered_text` - `Hello there`

  `- foo = bar`

    - `:statement` - `foo = bar`

  `doctype html5`

    - `:doctype` - `html5`
  """

  import Exslim.TokenizerTools

  @doc """
  Tokenizes a string.
  Returns a list of tokens. Each token is in the format `{position, token, value}`.

      tokenize("title= name")
      => [
        {0, :element_name, "title"},
        {7, :sole_buffered_text, "name"},
      ]
  """
  def tokenize(str) do
    run_tokenizer(str, &document/1)
  end

  def document(state) do
    state
    |> optional(&newlines/1)
    |> optional(&doctype/1)
    |> many_of(
      &(&1 |> element_or_text() |> newlines()),
      &(&1 |> element_or_text()))
  end

  def doctype(state) do
    state
    |> eat(~r/^doctype/, :doctype, nil)
    |> whitespace()
    |> eat(~r/^[^\n]+/, :doctype)
    |> optional(&newlines/1)
  end

  @doc """
  Consumes any number of blank newlines. Whitespaces are accounted for.
  """
  def newlines(state) do
    state
    |> eat(~r/^\n(?:[ \t]*\n)*/, :newlines, nil)
  end

  def indent(state) do
    state
    |> eat(~r/^\s*/, :indent)
  end

  def element_or_text(state) do
    state
    |> indent()
    |> one_of([
      &buffered_text/1,
      &raw_text/1,
      &statement/1,
      &element/1
    ])
  end

  @doc """
  Matches `div.foo[id="name"]= Hello world`
  """
  def element(state) do
    state
    |> element_descriptor()
    |> optional(&attributes_block/1)
    |> optional(fn s -> s
      |> one_of([
        &sole_buffered_text/1,
        &sole_raw_text/1
      ])
    end)
  end

  @doc """
  Matches `div`, `div.foo` `div.foo.bar#baz`, etc
  """
  def element_descriptor(state) do
    state
    |> one_of([
      &element_descriptor_full/1,
      &element_name/1,
      &element_class_or_id_list/1
    ])
  end

  @doc """
  Matches `div.foo.bar#baz`
  """
  def element_descriptor_full(state) do
    state
    |> element_name()
    |> element_class_or_id_list()
  end

  @doc """
  Matches `.foo.bar#baz`
  """
  def element_class_or_id_list(state) do
    state
    |> many_of(&element_class_or_id/1)
  end

  @doc """
  Matches `.foo` or `#id` (just one)
  """
  def element_class_or_id(state) do
    state
    |> one_of([ &element_class/1, &element_id/1 ])
  end

  @doc """
  Matches `.foo`
  """
  def element_class(state) do
    state
    |> eat(~r/^\./, :dot, nil)
    |> eat(~r/^[A-Za-z0-9_\-]+/, :element_class)
  end

  @doc """
  Matches `#id`
  """
  def element_id(state) do
    state
    |> eat(~r/^#/, :hash, nil)
    |> eat(~r/^[A-Za-z0-9_\-]+/, :element_id)
  end

  @doc """
  Matches `[name='foo' ...]`
  """
  def attributes_block(state) do
    state
    |> optional_whitespace()
    |> one_of([
      &attribute_bracket/1,
      &attribute_paren/1,
      &attribute_brace/1
    ])
  end

  def attribute_bracket(state) do
    state
    |> eat(~r/^\[/, :attribute_open)
    |> optional(&attribute_list/1)
    |> eat(~r/^\]/, :attribute_close)
  end

  def attribute_paren(state) do
    state
    |> eat(~r/^\(/, :attribute_open)
    |> optional(&attribute_list/1)
    |> eat(~r/^\)/, :attribute_close)
  end

  def attribute_brace(state) do
    state
    |> eat(~r/^\{/, :attribute_open)
    |> optional(&attribute_list/1)
    |> eat(~r/^\}/, :attribute_close)
  end

  @doc """
  Matches `foo='val' bar='val'`
  """
  def attribute_list(state) do
    state
    |> many_of(
      &(&1 |> attribute() |> whitespace()),
      &(&1 |> attribute()))
  end

  @doc """
  Matches `foo='val'`
  """
  def attribute(state) do
    state
    |> attribute_key()
    |> optional_whitespace()
    |> attribute_separator()
    |> optional_whitespace()
    |> attribute_value()
  end

  def attribute_key(state) do
    state
    |> eat(~r/^[A-Za-z][A-Za-z\-0-9]*/, :attribute_key)
  end

  def attribute_value(state) do
    state
    |> Exslim.ExpressionTokenizer.expression(:attribute_value)
  end

  def attribute_separator(state) do
    state
    |> one_of([
      &(&1 |> eat(~r/=/, :attribute_separator_eq, nil)),
      &(&1 |> eat(~r/:/, :attribute_separator_colon, nil))
    ])
  end

  @doc "Matches whitespace; no tokens emitted"
  def whitespace(state) do
    state
    |> eat(~r/^[ \t]+/, :whitespace, nil)
  end

  def optional_whitespace(state) do
    state
    |> eat(~r/^[ \t]*/, :optional_whitespace, nil)
  end

  @doc "Matches `=`"
  def sole_buffered_text(state) do
    state
    |> optional_whitespace()
    |> eat(~r/^=/, :eq, nil)
    |> optional_whitespace()
    |> eat(~r/^[^\n$]+/, :sole_buffered_text)
  end

  @doc "Matches text"
  def sole_raw_text(state) do
    state
    |> whitespace()
    |> eat(~r/^[^\n$]+/, :sole_raw_text)
  end

  @doc "Matches `title` in `title= hello`"
  def element_name(state) do
    state
    |> eat(~r/^[a-z]+/, :element_name)
  end

  def buffered_text(state) do
    state
    |> eat(~r/^=/, :eq, nil)
    |> optional_whitespace()
    |> eat(~r/^[^\n$]+/, :buffered_text)
  end

  def raw_text(state) do
    state
    |> eat(~r/^\|/, :pipe, nil)
    |> optional_whitespace()
    |> eat(~r/^[^\n$]+/, :raw_text)
  end

  def statement(state) do
    state
    |> eat(~r/^\-/, :pipe, nil)
    |> optional_whitespace()
    |> eat(~r/^[^\n$]+/, :statement)
  end
end
