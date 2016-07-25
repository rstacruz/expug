# Syntax: Comments

Comments begin with `//-`.

```jade
//- This is a comment
```

You may nest under it, and those lines will be ignored.

```jade
//- everything here is ignored:
  a(href="/")
    | Link
```

`-#` is also supported to keep consistency with Elixir.

```jade
-# This is also a comment
```

HTML comments
-------------

HTML comments begin with `//` (no hyphen). They will be rendered as `<!-- ... -->`.

```jade
// This is a comment
```

Also see
--------

- <http://jade-lang.com/reference/comments/>
