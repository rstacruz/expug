# Expug

> Indented shorthand HTML templates for Elixir

Expug is a template language based on [Pug][] (formerly known as [Jade][]).
This is a [work-in-progress](docs/todo.md).

[Pug]: http://www.pug-lang.com/
[Jade]: http://jade-lang.com/

## Installation

Add expug to your list of dependencies in `mix.exs`:

```elixir
def deps do
  #[{:expug, "~> 0.0.1"}]
  [{:expug, git: "https://github.com/rstacruz/expug.git"}]
end
```

Also see [phoenix_expug](https://github.com/rstacruz/phoenix_expug) for Phoenix integration.

## The language

Expug lets you write HTML as indented shorthand, inspired by Haml, Slim, Pug/Jade, and so on.

```jade
doctype html
html
  meta(charset="utf-8")
  title Hello, world!
body
  a(href=@link)
    | This is a link
```

Also see:

- [Comparison with Pug](docs/compatibility_with_pug.md)
- [Jade language reference](http://jade-lang.com/reference/) (jade-lang.com)

## Thanks

**expug** © 2016+, Rico Sta. Cruz. Released under the [MIT] License.<br>
Authored and maintained by Rico Sta. Cruz with help from contributors ([list][contributors]).

> [ricostacruz.com](http://ricostacruz.com) &nbsp;&middot;&nbsp;
> GitHub [@rstacruz](https://github.com/rstacruz) &nbsp;&middot;&nbsp;
> Twitter [@rstacruz](https://twitter.com/rstacruz)

[MIT]: http://mit-license.org/
[contributors]: http://github.com/rstacruz/expug/contributors
