# New line preservation

Eex has no provisions for source maps so we'll have to emulate.

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

## Building

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

Here's what happens:

- Multiline lines (like 6) will be joined with a fake newline (`<%= "\n" %>`).
- Empty lines (like line 4) will start with `<%`, with a final `%>` in the next line that has something.
