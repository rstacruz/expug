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
