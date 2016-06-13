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

```js
lines = %{
  1: [ {:line, "<div>"} ]
  2: [ {:line, "Hello,"} ]
  3: [ {:line, "<%= @name %>"} ]
  4: []
  5: [ {:line, "<button class="btn">"} ]
  6: [ {:line, "Save"}
       {:line, "</button>"}
       {:line, "</div>"} ]
}
```
