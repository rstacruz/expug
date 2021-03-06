# Changelog

## [v0.9.2]
> Oct 26, 2017

- Fix issue where elements with text (eg, `title Hello`) produce errors.

[v0.9.2]: https://github.com/rstacruz/expug/compare/v0.9.1...v0.9.2

## [v0.9.1]
> Oct 19, 2017

- Fix problem with value-less attributes (eg, `input(required type="text")`).

[v0.9.1]: https://github.com/rstacruz/expug/compare/v0.9.0...v0.9.1

## [v0.9.0]
> Oct 18, 2017

- [#10] - Fix Elixir 1.5.2 warnings about `String.rstrip/1`.
- [#8] - Fix `$` not being allowed in plain texts. ([@cubeguerrero], [#7])

[#10]: https://github.com/rstacruz/expug/issues/10
[#7]: https://github.com/rstacruz/expug/issues/7
[#8]: https://github.com/rstacruz/expug/issues/8
[@cubeguerrero]: https://github.com/cubeguerrero
[v0.9.0]: https://github.com/rstacruz/expug/compare/v0.8.0...v0.9.0

## [v0.8.0]
> Mar 14, 2017

- [#6] - Fixes consecutive if-else blocks.

[v0.8.0]: https://github.com/rstacruz/expug/compare/v0.7.3...v0.8.0

## [v0.7.3]
> Aug 29, 2016

- [#5] - Fixes problems with some nodes rendering as text.

[v0.7.3]: https://github.com/rstacruz/expug/compare/v0.7.2...v0.7.3

## [v0.7.2]
> Aug 29, 2016

- Fix multiline dot blocks (`script.`).

[v0.7.2]: https://github.com/rstacruz/expug/compare/v0.7.1...v0.7.2

## [v0.7.1]
> Jul 29, 2016

Squash Elixir warnings; no functional changes.

[v0.7.1]: https://github.com/rstacruz/expug/compare/v0.7.0...v0.7.1

## [v0.7.0]
> Jul 29, 2016

Support improved multiline. Write `=`, `!=` or `-` immediately followed by a newline. All text indented inside it will be treated as part of an Elixir expression.

```jade
=
  render App.MyView, "index.html",
  [conn: @conn] ++
  assigns
```

Error messages have also been improved.

[v0.7.0]: https://github.com/rstacruz/expug/compare/v0.6.0...v0.7.0

## [v0.6.0]
> Jul 25, 2016

Fix: Line comments have been changed from `-//` to `//-` (had a mistake in implementing that, sorry!)

[v0.6.0]: https://github.com/rstacruz/expug/compare/v0.5.0...v0.6.0

## [v0.5.0]
> Jul 25, 2016

HTML comments are now supported. They are just like `-//` comments, but they will render as `<!-- ... -->`.

```jade
// This is a comment
  (Anything below it will be part of the comment)
```

[v0.5.0]: https://github.com/rstacruz/expug/compare/v0.4.0...v0.5.0

## [v0.4.0]
> Jul 23, 2016

Value-less boolean attributes are now supported.

```jade
textarea(spellcheck)
```

Unescaped text (`!=`) is now supported.

```jade
div!= markdown_to_html(@article.body) |> sanitize()
```

You can now change the `raw` helper in case you're not using Phoenix. The `raw_helper` (which defaults to `"raw"` as Phoenix uses) is used on unfiltered text (such as `!= text`).

```ex
Expug.to_eex!("div= \"Hello\"", raw_helper: "")
```

[v0.4.0]: https://github.com/rstacruz/expug/compare/v0.3.0...v0.4.0

## [v0.3.0]
> Jul 21, 2016

[#3] - Attribute values are now escaped properly. This means you can now properly do:

```jade
- json = "{\"hello\":\"world\"}"
div(data-value=json)
```

```html
<div data-value="{&quot;hello&quot;:&quot;world&quot;}">
```

`nil` values are also now properly handled, along with boolean values.

```jade
textarea(spellcheck=nil)
textarea(spellcheck=true)
textarea(spellcheck=false)
```

```html
<textarea></textarea>
<textarea spellcheck></textarea>
<textarea></textarea>
```

[#3]: https://github.com/rstacruz/expug/issues/3
[v0.3.0]: https://github.com/rstacruz/expug/compare/v0.2.0...v0.3.0

## [v0.2.0]
> Jul 17, 2016

The new block text directive allows you to write text without Expug parsing.

```jade
script.
  if (usingExpug) {
    alert('Awesome!')
  }
```

Added support for multiline code. Lines ending in `{`, `(`, `[` or `,` will assume to be wrapped.

```jade
= render App.FooView, "nav.html",
  conn: @conn,
  action: {
    "Create new",
    item_path(@conn, :new) }
```

[v0.2.0]: https://github.com/rstacruz/expug/compare/v0.1.1...v0.2.0

## [v0.1.1]
> Jun 27, 2016

Expug now supports `if do ... end` and other blocks.

```jade
= if @error do
  .alert Uh oh! Check your form and try again.
```

[v0.1.1]: https://github.com/rstacruz/expug/compare/v0.0.1...v0.1.1

## [v0.0.1]
> Jun 26, 2016

Initial release.

[v0.0.1]: https://github.com/rstacruz/expug/tree/v0.0.1
[#5]: https://github.com/rstacruz/expug/issues/5
[#6]: https://github.com/rstacruz/expug/issues/6
