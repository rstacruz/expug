# Syntax: Elements

Elements are just lines.

```jade
div
```

## Class names and ID's

You may add `.classes` and `#id`s after an element name.

```jade
p.alert
div#box
```

If you do, the element name is optional.

```jade
#box
.alert
```

You may chain them as much as you need to.

```jade
.alert.alert-danger#error
```

## Attributes

Enclose attributes in `(...)` after an element name.

```jade
a(href="google.com") Google
a(class="button" href="google.com") Google
.box(style="display: none")
```

The attribute values are Elixir expressions.

```jade
script(src=static_path(@conn, "/js/app.js"))
```

## Text

Text after the classes/attributes are shown as plain text. See [text](text.html).

```jade
a(href="google.com") Google
```

You may also use `|` for plain text with other elements.

```jade
div
  | Welcome, new user!
  a(href="/signup") Register
```

## Nesting

Nest elements by indentation.

```jade
ul
  li
    a(href="/") Home
  li
    a(href="/about") About
```
