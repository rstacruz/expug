defmodule Expug do
  @moduledoc """
  Expug.
  """

  require Logger

  @doc ~S"""
  Compiles an Expug template to an Eex template.

      iex> source = "div\n  | Hello"
      iex> Expug.to_eex(source)
      {:ok, "<div>\nHello<%= \"\\n\" %></div>\n"}
  """
  def to_eex(source) do
    with {:ok, tokens} <- Expug.Tokenizer.tokenize(source),
         {:ok, ast} <- Expug.Compiler.compile(tokens),
         {:ok, lines} <- Expug.Builder.build(ast) do
       Expug.Stringifier.stringify(lines)
    end
  end

  def to_eex!(source) do
    case to_eex(source) do
      {:ok, eex} ->
        eex
      {:error, err} ->
        raise Expug.Error.exception(err)
    end
  end
end
