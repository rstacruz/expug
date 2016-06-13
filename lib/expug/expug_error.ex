defmodule Expug.Error do
  @moduledoc """
  A parse error
  """

  defexception [:message]

  def exception(%{type: type, position: {ln, col}}= err) do
    %Expug.Error{
      message: "line #{ln}:#{col}: " <> exception_message(type, err)
    }
  end

  def exception(err) do
    %Expug.Error{
      message: "error #{inspect(err)}"
    }
  end

  def exception_message(:parse_error, %{expected: expected}) do
    "parse error, expected one of: #{Enum.join(expected, ", ")}"
  end

  def exception_message(type, _) do
    "#{type} error"
  end
end
