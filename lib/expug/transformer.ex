defmodule Expug.Transformer do
  @moduledoc """
  Transforms a node after compilation.
  """

  alias Expug.Visitor

  # Helper for later
  defmacrop statement?(type) do
    quote do
      unquote(type) == :buffered_text or unquote(type) == :statement
    end
  end

  @doc """
  Transforms a node.
  """
  def transform(node) do
    node
    |> Visitor.visit(&close_statements/1)
  end

  def close_statements(%{children: children} = node) do
    children = close_statements_2(children)
    node = put_in(node.children, children)

    {:ok, node}
  end

  def clause_after("if"), do: ["else"]
  def clause_after("try"), do: ["catch", "rescue", "after"]
  def clause_after("catch"), do: ["catch", "after"]
  def clause_after("rescue"), do: ["rescue", "after"]
  def clause_after(_), do: []

  def close_statements_2(children) do
    closify(children)
  end

  @doc """
  Given a list of `children`, close the next if
  """
  def closify(children) do
    closify_clause(children, ["if", "try"])
  end

  def closify_clause([node | children], next) do
    pre = prelude(node)
    if statement?(node.type) and Enum.member?(next, pre) do
      case closify_clause(children, clause_after(pre)) do
        ^children -> # the next one is not else
          node = node |> Map.put(:close, "end")
          [node | closify(children)]
        new_children ->
          # changed
          [node | new_children]
      end
    else
      # Reset the chain
      [node | closify(children)]
    end
  end

  def closify_clause([], _upcoming) do
    [] # The last child is `if`
  end

  def closify_clause(children, [] = _upcoming) do
    children # Already closed end, but there's still more
  end

  @doc """
  Get the prelude of a given node

      xxx> prelude(%{value: "if foo")
      "if"

      xxx> prelude(%{value: "case derp"})
      "case"

      xxx> prelude(%{value: "1 + 2"})
      nil
  """
  def prelude(%{value: statement}) do
    case Regex.run(~r/\s*([a-z]+)/, statement) do
      [_, prelude] -> prelude
      _ -> nil
    end
  end

  def prelude(_) do
    nil
  end

  def close_statements(node) do
    {:ok, node}
  end

  # Checks if a given statement is open.
  defp open?(statement) do
    has_do = Regex.run(~r/[^A-Za-z0-9]do\s*$/, statement)
    has_do && true || false
  end
end
