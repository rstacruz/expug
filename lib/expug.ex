defmodule Expug do
  @moduledoc ~S"""
  Expug compiles templates to an eex template. See `to_eex/1`.

      iex> source = "div\n  | Hello"
      iex> Expug.to_eex(source)
      {:ok, "<div>\nHello<%= \"\\n\" %></div>\n"}

  There's also `to_eex!/1` which will instead return the result or throw an
  `Expug.Error`.

      iex> source = "div\n  | Hello"
      iex> Expug.to_eex!(source)
      "<div>\nHello<%= \"\\n\" %></div>\n"

  ## The `raw` helper
  Note that it needs `raw/1`, something typically provided by
  [Phoenix.HTML](http://devdocs.io/phoenix/phoenix_html/phoenix.html#raw/1).
  You don't need Phoenix.HTML however; a binding with `raw/1` would do.

      iex> Expug.to_eex!(~s[div(role="alert")= @message])
      "<div role=<%= raw(Expug.Runtime.attr_value(\"alert\")) %>><%= \"\\n\" %><%= @message %><%= \"\\n\" %></div>\n"

  ## Errors
  `to_eex/1` will give you this in case of an error:

      {:error, %{
        type: :parse_error,
        position: {3, 2},    # line/col
        ...                  # other metadata
      }}

  Internally, the other classes will throw `%{type, position, ...}` which will
  be caught here.

  ## Internal notes
  
  `Expug` pieces together 4 steps into a pipeline:

  - `Expug.Tokenizer`
  - `Expug.Compiler`
  - `Expug.Builder`
  - `Expug.Stringifier`
  """

  require Logger

  @doc ~S"""
  Compiles an Expug template to an EEx template. Returns `{:ok, result}`, where
  `result` is an EEx string. On error, it will return `{:error, ...}`.
  """
  def to_eex(source) do
    try do
      with tokens <- Expug.Tokenizer.tokenize(source),
           ast <- Expug.Compiler.compile(tokens),
           lines <- Expug.Builder.build(ast),
           eex <- Expug.Stringifier.stringify(lines) do
        {:ok, eex}
      end
    catch %{type: _type} = err->
      {:error, err}
    end
  end

  @doc ~S"""
  Compiles an Expug template to an EEx template.
  Returns the EEx string on success. On failure, it raises `Expug.Error`.
  """
  def to_eex!(source) do
    case to_eex(source) do
      {:ok, eex} ->
        eex
      {:error, err} ->
        raise Expug.Error.exception(err)
    end
  end
end
