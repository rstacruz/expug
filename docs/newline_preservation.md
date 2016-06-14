# New line preservation

Eex has no provisions for source maps, so we'll have to emulate this by outputing EEx that matches line numbers *exactly* with the source `.pug` files.

```jade
div
  | Hello,
  = @name

  button.btn
    | Save
```

```html
<div>
Hello,
<%= @name %>
<%
%><button class="btn">
Save<%="\n"%></button><%="\n"%></div>
```

## Internal notes

`Expug.Builder` brings this output:

```js
lines = %{
  :lines => 6,
  1 => [ "<div>" ],
  2 => [ "Hello," ],
  3 => [ "<%= @name %>" ],

  5 => [ "<button class="btn">" ],
  6 => [ "Save", "</button>", "</div>" ]
}
```

`Expug.Stringifier` will take this and yield a final EEx string. The rules it follows are:

- Multiline lines (like 6) will be joined with a fake newline (`<%= "\n" %>`).
- Empty lines (like line 4) will start with `<%`, with a final `%>` in the next line that has something.
