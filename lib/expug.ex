defmodule Expug do
  @moduledoc """
  Expug.

  ## AST

    [ type: :document,
      doctype: ...,
      children: [
        [ type: :element,
          classes: [
            [ type: :class, value: "blue" ],
            [ type: :class, value: "small" ]
          ],
          id: [ type: :id, value: "box" ],
          attributes: [
            [ type: :attribute,
              key: "href",
              value: [
                [ type: :expression, value: "\"hi\"" ]
              ]
            ]
          ],
          children: [
            ...
          ]
        ]
      ]
    ]
  """

  require Logger

  @doc ~S"""
  Compiles an Expug template to an Eex template.

      iex> source = "div Hello"
      iex> Expug.to_eex(source)
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
