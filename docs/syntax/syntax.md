# Syntax

The syntax is based on Pug (formerly known as Jade). Most of Pug's syntax is supported.

Elements
--------

Write elements in short CSS-like syntax. Express nesting through indentation.

```jade
.alert.alert-danger#error
  a(href="google.com") Google
```
See: [Elements](elements.html)

Code
----

Use `=` and `-` to run Elixir code.

```jade
= if @user do
  = "Welcome, #{@user.name}"
- else
  | You're not signed in.
```

See: [Code](code.html)

Text
----

Text nodes begin with `|`.

```jade
a(href="/signup")
  | Register now
```

See: [Text](text.html)

Comments
--------

```jade
-# This is a comment
-// this, too

// this is an HTML comment
```

See: [Comments](comments.html)

Doctype
-------

```jade
doctype html
```

See: [Doctype](doctype.html)

Compatibility with Pug
----------------------

Most of Pug's syntax is supported, with a few differences.
See: [Compatibility with Pug](compatibility_with_pug.html)
