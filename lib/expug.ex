defmodule Expug do
  @doc """
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

  def to_eex(source) do
    {:ok, tokens} = Expug.Tokenizer.tokenize(source)
    {:ok, ast} = Expug.Compiler.compile(tokens)
    {:ok, template} = Expug.Builder.build(ast)
    {:ok, template}
  end
end
