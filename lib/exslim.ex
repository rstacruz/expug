defmodule Exslim do
  @doc """
  Exslim.

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
    {:ok, tokens} = Exslim.Tokenizer.tokenize(source)
    {:ok, ast} = Exslim.Compiler.compile(tokens)
    {:ok, template} = Exslim.Builder.build(ast)
    {:ok, template}
  end
end
