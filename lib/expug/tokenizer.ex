defmodule Expug.Tokenizer do
  @moduledoc ~S"""
  Tokenizes a Slim template into a list of tokens. The main entry point is
  `tokenize/1`.

      iex> Expug.Tokenizer.tokenize("title= name")
      [
        {{1, 8}, :buffered_text, "name"},
        {{1, 1}, :element_name, "title"},
        {{1, 1}, :indent, 0}
      ]

  Note that the tokens are reversed! It's easier to append to the top of a list
  rather than to the end, making it more efficient.

  This output is the consumed next by `Expug.Compiler`, which turns them into
  an Abstract Syntax Tree.

  ## Token types

  ```
  div.blue#box
  ```

    - `:indent` - 0
    - `:element_name` - `"div"`
    - `:element_class` - `"blue"`
    - `:element_id` - `"box"`

  ```
  div(name="en")
  ```

    - `:attribute_open` - `"("`
    - `:attribute_key` - `"name"`
    - `:attribute_value` - `"\"en\""`
    - `:attribute_close` - `")"`

  ```
  div= hello
  ```

    - `:buffered_text` - `hello`

  ```
  div hello
  ```

    - `:raw_text` - `"hello"`

  ```
  | Hello there
  ```

    - `:raw_text` - `"Hello there"`

  ```
  = Hello there
  ```

    - `:buffered_text` - `"Hello there"`

  ```
  - foo = bar
  ```

    - `:statement` - `foo = bar`

  ```
  doctype html5
  ```

    - `:doctype` - `html5`

  ```
  -# comment
    more comments
  ```

    - `:line_comment` - `comment`
    - `:subindent` - `more comments`

  ## Also see
  - `Expug.TokenizerTools` has the functions used by this tokenizer.
  - `Expug.Compiler` uses the output of this tokenizer to build an AST.
  - `Expug.ExpressionTokenizer` is used to tokenize expressions.
  """

  import Expug.TokenizerTools
  alias Expug.TokenizerTools.State

  @doc """
  Tokenizes a string.
  Returns a list of tokens. Each token is in the format `{position, token, value}`.
  """
  def tokenize(source, opts \\ []) do
    source = String.rstrip(source)
    run(source, opts, &document/1)
  end

  @doc """
  Matches an entire document.
  """
  def document(state) do
    state
    |> optional(&newlines/1)
    |> optional(&doctype/1)
    |> many_of(
      &(&1 |> element_or_text() |> newlines()),
      &(&1 |> element_or_text()))
  end

  @doc """
  Matches `doctype html`.
  """
  def doctype(state) do
    state
    |> discard(~r/^doctype/, :doctype_prelude)
    |> whitespace()
    |> eat(~r/^[^\n]+/, :doctype)
    |> optional(&newlines/1)
  end

  @doc """
  Matches an HTML element, text node, or, you know... the basic statements.
  I don't know what to call this.
  """
  def element_or_text(state) do
    state
    |> indent()
    |> one_of([
      &line_comment/1,   # `-# hello`
      &html_comment/1,   # `// hello`
      &buffered_text/1,  # `= hello`
      &raw_text/1,       # `| hello`
      &statement/1,      # `- hello`
      &element/1         # `div.blue hello`
    ])
  end

  @doc """
  Matches any number of blank newlines. Whitespaces are accounted for.
  """
  def newlines(state) do
    state
    |> discard(~r/^\n(?:[ \t]*\n)*/, :newlines)
  end

  @doc """
  Matches an indentation. Gives a token that looks like `{_, :indent, 2}`
  where the last number is the number of spaces/tabs.

  Doesn't really care if you use spaces or tabs; a tab is treated like a single
  space.
  """
  def indent(state) do
    state
    |> eat(~r/^\s*/, :indent, &[{&3, :indent, String.length(&2)} | &1])
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
        &sole_raw_text/1,
        &free_text/1
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
    |> discard(~r/^\./, :dot)
    |> eat(~r/^[A-Za-z0-9_\-]+/, :element_class)
  end

  @doc """
  Matches `#id`
  """
  def element_id(state) do
    state
    |> discard(~r/^#/, :hash)
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
    |> optional_whitespace()
    |> optional(&attribute_list/1)
    |> eat(~r/^\]/, :attribute_close)
  end

  def attribute_paren(state) do
    state
    |> eat(~r/^\(/, :attribute_open)
    |> optional_whitespace()
    |> optional(&attribute_list/1)
    |> eat(~r/^\)/, :attribute_close)
  end

  def attribute_brace(state) do
    state
    |> eat(~r/^\{/, :attribute_open)
    |> optional_whitespace()
    |> optional(&attribute_list/1)
    |> eat(~r/^\}/, :attribute_close)
  end

  @doc """
  Matches `foo='val' bar='val'`
  """
  def attribute_list(state) do
    state
    |> optional_whitespace_or_newline()
    |> many_of(
      &(&1 |> attribute() |> attribute_separator() |> whitespace_or_newline()),
      &(&1 |> attribute()))
    |> optional_whitespace_or_newline()
  end

  @doc """
  Matches an optional comma in between attributes.

      div(id=a class=b)
      div(id=a, class=b)
  """
  def attribute_separator(state) do
    state
    |> discard(~r/^,?/, :comma)
  end

  @doc """
  Matches `foo='val'`
  """
  def attribute(state) do
    state
    |> attribute_key()
    |> optional_whitespace()
    |> attribute_equal()
    |> optional_whitespace()
    |> attribute_value()
  end

  def attribute_key(state) do
    state
    |> eat(~r/^[A-Za-z][A-Za-z\-0-9:]*/, :attribute_key)
  end

  def attribute_value(state) do
    state
    |> Expug.ExpressionTokenizer.expression(:attribute_value)
  end

  def attribute_equal(state) do
    state
    |> discard(~r/=/, :eq)
  end

  @doc "Matches whitespace; no tokens emitted"
  def whitespace(state) do
    state
    |> discard(~r/^[ \t]+/, :whitespace)
  end

  @doc "Matches whitespace or newline; no tokens emitted"
  def whitespace_or_newline(state) do
    state
    |> discard(~r/^[ \t\n]+/, :whitespace_or_newline)
  end

  def optional_whitespace(state) do
    state
    |> discard(~r/^[ \t]*/, :whitespace)
  end

  def optional_whitespace_or_newline(state) do
    state
    |> discard(~r/^[ \t\n]*/, :whitespace_or_newline)
  end

  @doc "Matches `=`"
  def sole_buffered_text(state) do
    state
    |> optional_whitespace()
    |> buffered_text()
  end

  @doc "Matches text"
  def sole_raw_text(state) do
    state
    |> whitespace()
    |> eat(~r/^[^\n$]+/, :raw_text)
  end

  @doc "Matches `title` in `title= hello`"
  def element_name(state) do
    state
    |> eat(~r/^[A-Za-z_][A-Za-z0-9:_\-]*/, :element_name)
  end

  def line_comment(state) do
    state
    |> discard(~r/^-\s*(?:#|\/\/)/, :line_comment)
    |> optional_whitespace()
    |> eat(~r/^[^\n]*/, :line_comment)
    |> optional(&subindent_block/1)
  end

  def free_text(state) do
    state
    |> eat(~r/\./, :free_text)
    |> subindent_block()
  end

  def subindent_block(state) do
    sublevel = state |> get_next_indent()
    state
    |> many_of(& &1 |> newlines() |> subindent(sublevel))
  end

  def subindent(state, level) do
    state
    |> discard(~r/^[ \t]{#{level}}/, :whitespace)
    |> eat(~r/^[^\n]*/, :subindent)
  end

  def get_indent([{_, :indent, text} | _]) do
    text
  end

  def get_indent([_ | rest]) do
    get_indent(rest)
  end

  def get_indent([]) do
    ""
  end

  def html_comment(state) do
    state
    |> discard(~r[^//], :html_comment)
    |> optional_whitespace()
    |> eat(~r/^[^\n$]*/, :html_comment)
    |> optional(&subindent_block/1)
  end

  def buffered_text(state) do
    state
    |> discard(~r/^=/, :eq)
    |> optional_whitespace()
    |> eat(~r/^[^\n$]+/, :buffered_text)
  end

  def raw_text(state) do
    state
    |> discard(~r/^\|/, :pipe)
    |> optional_whitespace()
    |> eat(~r/^[^\n]+/, :raw_text)
  end

  def statement(state) do
    state
    |> discard(~r/^\-/, :dash)
    |> optional_whitespace()
    |> eat(~r/^[^\n$]+/, :statement)
  end

  @doc ~S"""
  Returns the next indentation level after some newlines.
  Infers the last indentation level based on `doc`.

      iex> source = "-#\n  span"
      iex> doc = [{0, :indent, 0}]
      iex> Expug.Tokenizer.get_next_indent(%{tokens: doc, source: source, position: 2}, 0)
      2
  """
  def get_next_indent(%State{tokens: doc} = state) do
    level = get_indent(doc)
    get_next_indent(state, level)
  end

  @doc ~S"""
  Returns the next indentation level after some newlines.

      iex> source = "-#\n  span"
      iex> Expug.Tokenizer.get_next_indent(%{tokens: [], source: source, position: 2}, 0)
      2

      iex> source = "-#\n\n\n  span"
      iex> Expug.Tokenizer.get_next_indent(%{tokens: [], source: source, position: 2}, 0)
      2
  """
  def get_next_indent(state, level) do
    %{tokens: [{_, :indent, sublevel} |_], position: pos} =
      state |> newlines() |> indent()
    if sublevel <= level, do: throw {:parse_error, pos, [:indent]}
    sublevel
  end
end
