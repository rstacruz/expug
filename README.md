<img src="https://cdn.rawgit.com/pugjs/pug-logo/eec436cee8fd9d1726d7839cbe99d1f694692c0c/SVG/pug-final-logo-_-colour-128.svg" align="right" height="175" width="218">

# Expug

> Indented shorthand HTML templates for Elixir

[![](https://img.shields.io/github/stars/rstacruz/expug.svg?style=social)](https://github.com/rstacruz/expug)

Expug is a template language based on [Pug][] (formerly known as [Jade][]).
It lets you write HTML as indented shorthand, inspired by Haml, Slim, Pug/Jade, and so on.

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

[![Status](https://travis-ci.org/rstacruz/expug.svg?branch=master)](https://travis-ci.org/rstacruz/expug "See test builds")

[Pug]: http://pugjs.org/
[Jade]: http://jade-lang.com/

## Installation

Add expug to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:expug, "~> 0.8"}]
end
```

Also see [phoenix_expug](https://github.com/rstacruz/phoenix_expug) for Phoenix integration.

## Syntax

Use CSS-like selectors for elements, and express your nesting through indentations.

```jade
ul.links
  li
    a(href="/") This is a link
```

Read more: [Syntax](https://hexdocs.pm/expug/syntax.html)

## Why should I use it?

Read on [this comparison](https://hexdocs.pm/expug/prior_art.html) to see how Expug compares to other similar libraries.

## Thanks

**expug** © 2016+, Rico Sta. Cruz. Released under the [MIT] License.<br>
Authored and maintained by Rico Sta. Cruz with help from contributors ([list][contributors]).

> [ricostacruz.com](http://ricostacruz.com) &nbsp;&middot;&nbsp;
> GitHub [@rstacruz](https://github.com/rstacruz) &nbsp;&middot;&nbsp;
> Twitter [@rstacruz](https://twitter.com/rstacruz)

[MIT]: http://mit-license.org/
[contributors]: http://github.com/rstacruz/expug/contributors

<p><iframe src="https://ghbtns.com/github-btn.html?user=rstacruz&type=follow&count=true" frameborder="0" scrolling="0" width="170px" height="20px"></iframe></p>
