# Expug

> Pug templates for Elixir

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add expug to your list of dependencies in `mix.exs`:

        def deps do
          [{:expug, "~> 0.0.1"}]
        end

  2. Ensure expug is started before your application:

        def application do
          [applications: [:expug]]
        end

## To Do

This is a work in progress.

- [95%] String -> Tokens (`tokens = Expug.Tokenizer.tokenize(str)`)
- [80%] Tokens -> AST (`ast = Expug.Compiler.compile(tokens)`) - *getting there!*
- [1%] AST -> EEx templates (`eex = Expug.Builder.build(ast)`)

Supported:

- [x] Most everything
- [x] track line/column in tokens
- [ ] `!=` unescaped code
- [ ] HTML escaping
- [ ] `/` comments
- [ ] `,` comma-delimited attributes
- [ ] Multiline expressions
- [ ] `.` raw text (like `script.`)
