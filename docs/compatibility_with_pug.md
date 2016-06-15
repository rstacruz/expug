# Compatibility with Pug

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

- __Comments__ are done using `-#` instead of `-//`, following Elixir conventions.

- __Text attributes__ need to have double-quoted strings (`"`). Single-line strings will translate to Elixir char lists, which is likely not what you want.

## Removed

- The following features are not available: `block`, `include`, `extends`.

## The same

- __Indent sensitivity__ rules of Pug/Jade have been preserved. This means you can do:

  ```jade
  html
    head
        title This is indented with 4 spaces
  ```
