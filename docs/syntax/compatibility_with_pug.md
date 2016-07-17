# Syntax: Compatibility with Pug

Expug retains most of Pug/Jade's features, adds some Elixir'isms, and drops the features that don't make sense.

## Added

- __Multiline attributes__ are supported. As long as you use balanced braces, Expug is smart enough to know when to count the next line as part of an expression.

  ```jade
  button.btn(
    role='btn'
    class=(
      get_classname(@button)
    )
  )= get_text "Submit"
  ```

## Changed

- __Comments__ are done using `-#` as well as `-//`, following Elixir conventions. The old `-//` syntax is supported for increased compatibility with text editor syntax highlighting.

- __Text attributes__ need to have double-quoted strings (`"`). Single-line strings will translate to Elixir char lists, which is likely not what you want.

- __Statements with blocks__ like `= if .. do` ... `- end` should start with `=`, and end in `-`. This is the same as you would do in EEx.

## Removed

The following features are not available due to the limitations of EEx.

- [include](http://jade-lang.com/reference/includes) (partials)
- [block/extends](http://jade-lang.com/reference/extends) (layouts & template inheritance)
- [mixins](http://jade-lang.com/reference/mixins) (functions)

The following syntactic sugars, are not implemented, simply because they're not idiomatic Elixir. There are other ways to accomplish them.

- [case](http://jade-lang.com/reference/case/)
- [conditionals](http://jade-lang.com/reference/conditionals)
- [iteration](http://jade-lang.com/reference/iteration)

The following are still unimplemented, but may be in the future.

- [filters](http://jade-lang.com/reference/case/)
- [interpolation](http://jade-lang.com/reference/interpolation/)
- multi-line statements (`-\n  ...`)

The following are unimplemented, just because I don't want to implement them.

- Doctype shorthands are limited to only `html` and `xml`. The [XHTML shorthands](http://jade-lang.com/reference/doctype/) were not implemented to discourage their use.

## The same

- __Indent sensitivity__ rules of Pug/Jade have been preserved. This means you can do:

  ```jade
  html
    head
        title This is indented with 4 spaces
  ```
