defmodule Expug.Stringifier do
  @moduledoc """
  Stringifies builder output.

  ## Also see
  - `Expug.Builder` builds the line map used by this stringifier.
  - `Expug.to_eex/1` is the main entry point that uses this stringifier.
  """

  def stringify(%{} = doc, _opts \\ []) do
    {max, doc} = Map.pop(doc, :lines)
    {_, doc} = Map.pop(doc, :doctype)
    list = doc |> Map.to_list() |> Enum.sort()

    # Move the newline to the end
    "\n" <> rest = render_lines(list, 0, max)
    rest <> "\n"
  end

  # Works on a list of `{2, ["<div>"]}` tuples.
  # Each pass works on one line.
  #
  #     %{
  #       :lines => 2,
  #       1 => ["<div>"],
  #       2 => ["<span></span>", "</div>"]
  #     }
  #
  # Renders into these in 2 passes:
  #
  #     "\n<div>"
  #     "\n<span></span><%= "\n" %></div>"
  #
  defp render_lines([{line, elements} | rest], last, max) do
    {padding, meat} = render_elements(elements, line, last)
    cursor = line + count_newlines(meat)

    padding <> meat <> render_lines(rest, cursor, max)
  end

  defp render_lines([], _last, _max) do
    ""
  end

  # Renders a line. If it starts with :collapse, don't give
  # the `\n`
  defp render_elements([:collapse | elements], line, last) do
    { padding(line, last - 1),
      Enum.join(elements, ~S[<%= "\n" %>]) }
  end

  defp render_elements(elements, line, last) do
    { "\n" <> padding(line, last),
      Enum.join(elements, ~S[<%= "\n" %>]) }
  end

  # Counts the amount of newlines in a string
  defp count_newlines(str) do
    length(Regex.scan(~r/\n/, str))
  end

  # Contructs `<% .. %>` padding. Used to fill in blank lines
  # in the source.
  defp padding(line, last) when line - last - 1 <= 0 do
    ""
  end

  defp padding(line, last) do
    "<%" <> newlines(line - last - 1) <> "%>"
  end

  # Gives `n` amounts of newlines.
  def newlines(n) when n <= 0 do
    ""
  end

  def newlines(n) do
    "\n" <> newlines(n - 1)
  end
end
