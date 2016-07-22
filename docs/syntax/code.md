# Syntax: Code

## Unbuffered code
Unbuffered code starts with `-` does not add any output directly.

```jade
- name = assigns.name
div(id="name-#{name}")
```

## Bufferred code

Buffered code starts with `=` and outputs the result of evaluating the Elixir expression in the template. For security, it is first HTML escaped.

```jade
p= "Hello, #{name}"
```

## Unescaped code

Buffered code may be unescaped by using `!=`. This skips the HTML escaping.

```jade
div!= markdown_to_html(@article.body) |> sanitize()
```

## Conditionals and Loops

For `if`, `cond`, `try`, `for`, an `end` statement is automatically inferred.

```jade
= if assigns.name do
  = "Hello, #{@name}"
```

They also need to begin with `=`, not `-`. Except for `else`, `rescue` and so on.

```jade
= if assigns.current_user do
  | Welcome.
- else
  | You are not signed in.
```

## Multiline

If a line ends in one of these characters: `,` `(` `{` `[`, the next line is considered to be part of the Elixir expression.

```jade
= render App.PageView,
  "index.html",
  conn: @conn
```
