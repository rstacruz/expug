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
    "\"" <> str <> "\""
  end
end
