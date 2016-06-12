defmodule Expug.ParseError do
  @moduledoc """
  A parse error
  """

  defexception [:position, :expected, :str]
end
