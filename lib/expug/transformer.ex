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

  def close_statements_2(children) do
    closify(children, ["if", "else"])
  end

  def close_statements_2(children) do
    children
  end

  @doc """
  Given a list of `children`, close the next if
  """
  def closify(children, statements) do
    closify(children, statements, statements)
  end

  def closify([node | children], statements, upcoming) do
    [next | rest] = upcoming

    if statement?(node.type) and prelude(node.value) == next do
      case closify(children, statements, rest) do
        ^children -> # the next one is not else
          node = node |> Map.put(:close, "end")
          [node | children]
        new_children ->
          # changed
          [node | new_children]
      end
    else
      [node | children]
    end
  end

  def closify([], _statements, _upcoming) do
    [] # The last child is `if`
  end

  def closify(children, _statements, [] = _upcoming) do
    children # Already closed end, but there's still more
  end

  @doc """
  Get the prelude of a statement

      xxx> prelude("if foo")
      "if"

      xxx> prelude("case derp")
      "case"

      xxx> prelude("1 + 2")
      nil
  """
  def prelude(statement) do
    case Regex.run(~r/\s*([a-z]+)/, statement) do
      [_, prelude] -> prelude
      _ -> nil
    end
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
