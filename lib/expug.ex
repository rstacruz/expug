defmodule Expug do
  @moduledoc ~S"""
  Expug compiles templates to an eex template.
  
  `to_eex/2` turns an Expug source into an EEx template.

      iex> source = "div\n  | Hello"
      iex> Expug.to_eex(source)
      {:ok, "<div>\nHello<%= \"\\n\" %></div>\n"}

  `to_eex!/2` is the same, and instead returns the result or throws an
  `Expug.Error`.

      iex> source = "div\n  | Hello"
      iex> Expug.to_eex!(source)
      "<div>\nHello<%= \"\\n\" %></div>\n"

  ## Errors
  `to_eex/2` will give you this in case of an error:

      {:error, %{
        type: :parse_error,
        position: {3, 2},    # line/col
        ...                  # other metadata
      }}

  Internally, the other classes will throw `%{type, position, ...}` which will
  be caught here.

  ## The `raw` helper
  Note that it needs `raw/1`, something typically provided by
  [Phoenix.HTML](http://devdocs.io/phoenix/phoenix_html/phoenix.html#raw/1).
  You don't need Phoenix.HTML however; a binding with `raw/1` would do.

      iex> Expug.to_eex!(~s[div(role="alert")= @message])
      "<div role=<%= raw(Expug.Runtime.attr_value(\"alert\")) %>><%= \"\\n\" %><%= @message %><%= \"\\n\" %></div>\n"

  ## Internal notes
  
  `Expug.to_eex/2` pieces together 4 steps into a pipeline:

  - `tokenize/2` - turns source into tokens.
  - `compile/2` - turns tokens into an AST.
  - `build/2` - turns an AST into a line map.
  - `stringify/2` - turns a line map into an EEx template.

  ## Also see

  - `Expug.Tokenizer`
  - `Expug.Compiler`
  - `Expug.Builder`
  - `Expug.Stringifier`
  """

  defdelegate tokenize(source, opts), to: Expug.Tokenizer
  defdelegate compile(tokens, opts), to: Expug.Compiler
  defdelegate build(ast, opts), to: Expug.Builder
  defdelegate stringify(lines, opts), to: Expug.Stringifier

  @doc ~S"""
  Compiles an Expug template to an EEx template.
  
  Returns `{:ok, result}`, where `result` is an EEx string. On error, it will
  return `{:error, ...}`.
  """
  def to_eex(source, opts \\ []) do
    try do
      eex = source
      |> tokenize(opts)
      |> compile(opts)
      |> build(opts)
      |> stringify(opts)
      {:ok, eex}
    catch %{type: _type} = err->
      {:error, err}
    end
  end

  @doc ~S"""
  Compiles an Expug template to an EEx template and raises errors on failure.

  Returns the EEx string on success. On failure, it raises `Expug.Error`.
  """
  def to_eex!(source, opts \\ []) do
    case to_eex(source, opts) do
      {:ok, eex} ->
        eex
      {:error, err} ->
        raise Expug.Error.exception(err)
    end
  end
end
