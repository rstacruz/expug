# Misc: Prior art

There's [calliope] and [slime] that brings Haml and Slim to Elixir, respectively. Expug offers a bit more:

## Pug/Jade syntax!

Pug/Jade's syntax is something I personally find more sensible than Slim.

```
p.alert(align="center")      # Expug

%p.alert{align: "center"}    # HAML
```

## True multilines

Expug has a non-line-based tokenizer that can figure out multiline breaks.

```
= render App.UserView,
  "show.html",
  conn: @conn

div(
  style="font-weight: bold"
  role="alert"
)
```

## Correct line number errors

Errors in Expug will always map to the correct source line numbers.

> CompileError in show.html.pug (line 2):<br>
> assign @xyz not available in eex template.

[calliope]: https://github.com/nurugger07/calliope
[slime]: https://github.com/slime-lang/slime
