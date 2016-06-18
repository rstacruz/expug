defmodule Expug.Visitor do
  @moduledoc """
  Internal helper for traversing an AST.

      iex> node = %{
      ...>   title: "Hello",
      ...>   children: [
      ...>     %{title: "fellow"},
      ...>     %{title: "humans"}
      ...>   ]
      ...> }
      iex> Expug.Visitor.visit(node, fn node ->
      ...>   Map.update(node, :title, ".", &(&1 <> "."))
      ...> end)
      %{
         title: "Hello.",
         children: [
           %{title: "fellow."},
           %{title: "humans."}
         ]
      }
  """

  @doc """
  Returns a function `fun` recursively across `node` and its descendants.
  """
  def visit(node, fun) do
    node = fun.(node)
    visit_children(node, fun)
  end

  @doc false
  defp visit_children(%{children: children} = node, fun) do
    Map.put(node, :children, (for c <- children, do: visit(c, fun)))
  end

  @doc false
  defp visit_children(node, _) do
    node
  end
end
