defmodule Expug.Error do
  @moduledoc """
  A parse error
  """

  defexception [:message, :line, :column]

  def exception(%{type: type, position: {ln, col}}= err) do
    %Expug.Error{
      message: exception_message(type, err) <> " on line #{ln} col #{col}",
      line: ln,
      column: col
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

  def exception_message(:ambiguous_indentation, _) do
    "ambiguous indentation"
  end

  def exception_message(type, _) do
    "#{type} error"
  end
end
