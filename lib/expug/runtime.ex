defmodule Expug.Runtime do
  @moduledoc """
  Functions used by Expug-compiled templates at runtime.

  ```eex
  <div class=<%= raw(Expug.Runtime.attr_value(str)) %>></div>
  ```
  """

  @doc """
  Quotes a given `str` for use as an HTML attribute.
  """
  def attr_value(str) do
    "\"#{attr_value_escape(str)}\""
  end

  def attr_value_escape(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("\"", "&quot;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  def attr(key, true) do
    " " <> key
  end

  def attr(_key, false) do
    ""
  end

  def attr(_key, nil) do
    ""
  end

  def attr(key, value) do
    " " <> key <> "=" <> attr_value(value)
  end
end
