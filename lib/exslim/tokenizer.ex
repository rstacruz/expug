defmodule Exslim.Tokenizer do
  @moduledoc """
  Tokenizer
  """

  use Exslim.TokenizerTools

  @doc """
  Tokenizes a string.
  Returns a list of tokens. Each token is in the format `{position, token, value}`.

      tokenize("title= name")
      => [
        {0, :element_name, "title"},
        {5, :buffered_text},
        {7, :text, "name"}
      ]
  """
  def tokenize(str) do
    run_tokenizer str, &(elements(&1))
  end

  def elements(state) do
    state
    |> many_of(
      &(&1 |> element() |> newline()),
      &(&1 |> element()))
  end

  def newline(state) do
    eat state, ~r/^\n/, :newline, nil
  end

  def indent(state) do
    eat state, ~r/^\s*/, :indent
  end

  def element(state) do
    state
    |> indent()
    |> element_descriptor()
    |> optional(&attributes_block/1)

    # Text
    |> optional(fn s -> s
      |> optional(&buffered_text/1)
      |> whitespace()
      |> text()
    end)
  end

  @doc """
  Matches `div`, `div.foo` `div.foo.bar#baz`, etc
  """
  def element_descriptor(state) do
    state
    |> one_of([
      &element_descriptor_full/1,
      &element_descriptor_name/1,
      &element_descriptor_class/1
    ])
  end

  def element_descriptor_name(state) do
    state
    |> element_name()
  end

  def element_descriptor_class(state) do
    state
    |> element_class_or_id_list()
  end

  def element_descriptor_full(state) do
    state
    |> element_name()
    |> element_class_or_id_list()
  end

  def element_class_or_id_list(state) do
    state
    |> many_of(&element_class_or_id/1)
  end

  def element_class_or_id(state) do
    state
    |> one_of([ &element_class/1, &element_id/1 ])
  end

  def element_class(state) do
    state
    |> eat(~r/^\./, :dot, nil)
    |> eat(~r/^[A-Za-z0-9_\-]+/, :element_class)
  end

  def element_id(state) do
    state
    |> eat(~r/^#/, :hash, nil)
    |> eat(~r/^[A-Za-z0-9_\-]+/, :element_id)
  end

  def attributes_block(state) do
    state
    |> optional_whitespace()
    |> one_of([
      &attribute_bracket/1,
      &attribute_paren/1,
      &attribute_curly/1
    ])
  end

  def attribute_bracket(state) do
    state
    |> eat(~r/^\[/, :attribute_open)
    |> attribute_contents()
    |> eat(~r/^\]/, :attribute_close)
  end

  def attribute_paren(state) do
    state
    |> eat(~r/^\(/, :attribute_open)
    |> attribute_contents()
    |> eat(~r/^\)/, :attribute_close)
  end

  def attribute_curly(state) do
    state
    |> eat(~r/^\{/, :attribute_open)
    |> attribute_contents()
    |> eat(~r/^\}/, :attribute_close)
  end

  @doc "Matches `foo='val' bar='val'`"
  def attribute_contents(state) do
    state
    |> optional(&attribute_list/1)
  end

  def attribute_list(state) do
    state
    |> many_of(
      &(&1 |> attribute() |> whitespace()),
      &(&1 |> attribute()))
  end

  @doc "Matches `foo='val'`"
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
    |> eat(~r/^"[^"]*"/, :attribute_value)
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
    eat state, ~r/^[ \t]+/, :whitespace, nil
  end

  def optional_whitespace(state) do
    eat state, ~r/^[ \t]*/, :optional_whitespace, nil
  end

  @doc "Matches `=`"
  def buffered_text(state) do
    eat state, ~r/^=/, :buffered_text
  end

  @doc "Matches text"
  def text(state) do
    eat state, ~r/^[^\n$]+/, :text
  end

  @doc "Matches `title` in `title= hello`"
  def element_name(state) do
    eat state, ~r/^[a-z]+/, :element_name
  end
end
