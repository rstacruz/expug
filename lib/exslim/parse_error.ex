defmodule Exslim.ParseError do
  @moduledoc """
  A parse error
  """

  defexception [:message, :position]
end
