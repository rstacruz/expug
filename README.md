# Expug

> Indented shorthand HTML templates for Elixir

Expug is a template language based on [Pug][] (formerly known as [Jade][]).
This is a work-in-progress.

[![Status](https://travis-ci.org/rstacruz/expug.svg?branch=master)](https://travis-ci.org/rstacruz/expug "See test builds")

[Pug]: http://www.pug-lang.com/
[Jade]: http://jade-lang.com/

## Installation

Add expug to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:expug, "~> 0.1.1"}]
end
```

Also see [phoenix_expug](https://github.com/rstacruz/phoenix_expug) for Phoenix integration.

## The language

Expug lets you write HTML as indented shorthand, inspired by Haml, Slim, Pug/Jade, and so on.

<iframe src='https://try-expug.herokuapp.com/try?code=doctype%20html%0Ahtml%0A%20%20head%0A%20%20%20%20meta(charset%3D%22utf-8%22)%0A%20%20%20%20title%20Hello%0A%20%20body%0A%20%20%20%20a.button(href%3D%40link)%0A%20%20%20%20%20%20%7C%20This%20is%20a%20link' height='400' width='100%' style='border: 0'></iframe>

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

- [Comparison with Pug](docs/misc/compatibility_with_pug.md)
- [Jade language reference](http://jade-lang.com/reference/) (jade-lang.com)

## Prior art

There's [calliope] and [slime] that brings Haml and Slim to Elixir, respectively. Expug offers a bit more:

- Jade syntax! - something I personally find more sensible than Slim.
- True multilines - Expug has a non-line-based tokenizer that can figure out multiline breaks.
- Correct line number errors - Errors in Expug will always map to the correct source line numbers.

[calliope]: https://github.com/nurugger07/calliope
[slime]: https://github.com/slime-lang/slime

## How it works

Expug converts a `.pug` template into an EEx string:

```elixir
iex> Expug.to_eex!(~s[div(role="alert")= @message])
"<div role=<%= raw(\"alert\") %>><%= @message %>"
```

See the module `Expug` for details.

To use Expug with Phoenix, see [phoenix_expug](https://github.com/rstacruz/phoenix_expug).

## Thanks

**expug** © 2016+, Rico Sta. Cruz. Released under the [MIT] License.<br>
Authored and maintained by Rico Sta. Cruz with help from contributors ([list][contributors]).

> [ricostacruz.com](http://ricostacruz.com) &nbsp;&middot;&nbsp;
> GitHub [@rstacruz](https://github.com/rstacruz) &nbsp;&middot;&nbsp;
> Twitter [@rstacruz](https://twitter.com/rstacruz)

[MIT]: http://mit-license.org/
[contributors]: http://github.com/rstacruz/expug/contributors
