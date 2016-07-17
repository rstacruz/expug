# Syntax: Comments

Comments begin with `-#`.

```jade
-# This is a comment
```

You may nest under it, and those lines will be ignored.

```jade
-# everything here is ignored:
  a(href="/")
    | Link
```

`-//` is also supported to keep consistency with Pug/Jade.

```jade
-// This is also a comment
```

HTML comments begin with a `/`.

```jade
/ This is a comment
```
