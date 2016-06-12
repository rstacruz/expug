# Exslim

> Slim templates for Elixir

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add exslim to your list of dependencies in `mix.exs`:

        def deps do
          [{:exslim, "~> 0.0.1"}]
        end

  2. Ensure exslim is started before your application:

        def application do
          [applications: [:exslim]]
        end

## To Do

This is a work in progress.

- [ ] String -> Tokens (`Exslim.Tokenizer.tokenize(str)`) - *getting there!*
- [ ] Tokens -> AST (`Exslim.Compiler.compile(tokens)`) - *getting there!*
- [ ] AST -> EEx (`Exslim.Builder.build(tokens)`)
