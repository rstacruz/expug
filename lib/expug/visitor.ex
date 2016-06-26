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
      ...>   {:ok, Map.update(node, :title, ".", &(&1 <> "."))}
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
    {continue, node} = fun.(node)
    if continue == :ok do
      visit_recurse(node, fun)
    else
      node
    end
  end

  @doc """
  Visits all children lists recursively across `node` and its descendants.

  Works just like `visit/2`, but instead of operating on nodes, it operates on
  node children (lists).
  """
  def visit_children(node, fun) do
    visit node, fn
      %{children: children} = node ->
        children = fun.(children)
        node = put_in(node.children, children)
        {:ok, node}
      node ->
        {:ok, node}
    end
  end

  defp visit_recurse(%{children: children} = node, fun) do
    Map.put(node, :children, (for c <- children, do: visit(c, fun)))
  end

  defp visit_recurse(node, _) do
    node
  end
end
