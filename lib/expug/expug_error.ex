defmodule Expug.Error do
  @moduledoc """
  A parse error
  """

  defexception [:message, :line, :column]

  def exception(%{type: type, position: {ln, col}, source: source} = err) do
    {message, description} = exception_message(type, err)
    line_source = source |> String.split("\n") |> Enum.at(ln - 1)
    indent = repeat_string(col - 1, " ")

    %Expug.Error{
      message:
         "#{message} on line #{ln}\n\n"
         <> "    #{line_source}\n"
         <> "    #{indent}^\n\n"
         <> description,
      line: ln,
      column: col
    }
  end

  def repeat_string(times, string \\ " ") do
    1..times |> Enum.reduce("", fn n, acc -> acc <> string end)
  end

  def exception(err) do
    %Expug.Error{
      message: "Error #{inspect(err)}"
    }
  end

  def exception_message(:parse_error, %{expected: expected}) do
    {
      "Parse error",
      """
      Expug encountered a character it didn't expect.
      Expected one of:

      * #{Enum.join(expected, "\n* ")}
      """
    }
  end

  def exception_message(:unexpected_indent, _) do
    {
      "Unexpected indentation",
      """
      Expug found spaces when it didn't expect any.
      """
    }
  end

  def exception_message(:ambiguous_indentation, _) do
    {
      "Ambiguous indentation",
      """
      Expug found spaces when it didn't expect any.
      """
    }
  end

  def exception_message(type, _) do
    {
      "#{type} error",
      """
      Expug encountered a #{type} error.
      """
    }
  end
end
