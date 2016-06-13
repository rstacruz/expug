defmodule Expug do
  @moduledoc """
  Expug.
  """

  require Logger

  @doc ~S"""
  Compiles an Expug template to an Eex template.

      ###> source = "div Hello"
      ###> Expug.to_eex(source)
      {:ok, "<div>\nHello\n</div>\n"}
  """
  def to_eex(source) do
    with {:ok, tokens} <- Expug.Tokenizer.tokenize(source),
         {:ok, ast} <- Expug.Compiler.compile(tokens) do
      Logger.debug(inspect(tokens))
      Logger.debug(inspect(ast))
      Expug.Builder.build(ast)
    end
  end
end
