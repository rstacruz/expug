# Misc: How it works

Expug converts a `.pug` template into an EEx string:

```elixir
iex> Expug.to_eex!(~s[div(role="alert")= @message])
"<div role=<%= raw(\"alert\") %>><%= @message %>"
```

See the module `Expug` for details.
