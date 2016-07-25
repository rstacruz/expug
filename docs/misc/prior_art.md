# Misc: Prior art

> a.k.a., "Why should I use Expug over other template engines?"

There's [calliope] and [slime] that brings Haml and Slim to Elixir, respectively. Expug offers a bit more:

## Pug/Jade syntax!

The Pug syntax is something I personally find more sensible than Slim, and less noisy than Haml.

```
# Expug
p.alert(align="center") Hello!

# HAML
%p.alert{align: "center"} Hello!

# Slime
p.alert align="center" Hello!
```

Expug tries to infer what you mean based on balanced parentheses. In contrast, you're forced to use `"#{...}"` in slime.

```
# Expug
script(src=static_path(@conn, "/js/app.js") type="text/javascript")
#          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# Slime
script[src="#{static_path(@conn, "/js/app.js")}" type="text/javascript"]
```

Also notice that you're forced to use `[` in Slime if your attributes have `(` in it. Expug doesn't have this restriction.

```
# Slime
a(href="/")
a(href="/link")
a[href="/link" onclick="alert('Are you sure?')"]
```

Slime has optional braces, which leads to a lot of confusion. In Expug, parentheses are required.

```
# Slime
strong This is bold text.
strong color="blue" This is also valid, but confusing.

# Expug
strong(color="blue") Easier and less confusing!
```


## True multilines

Expug has a non-line-based tokenizer that can figure out multiline breaks.

```
# Expug
= render App.UserView,
  "show.html",
  conn: @conn

div(
  style="font-weight: bold"
  role="alert"
)
```

Using brace-matching, Expug's parser can reliably figure out what you mean.

```
# Expug
script(
  src=static_path(
    @conn,
    "/js/app.js"))
```

## Correct line number errors

Errors in Expug will always map to the correct source line numbers.

> CompileError in show.html.pug (line 2):<br>
> assign @xyz not available in eex template.

[calliope]: https://github.com/nurugger07/calliope
[slime]: https://github.com/slime-lang/slime
