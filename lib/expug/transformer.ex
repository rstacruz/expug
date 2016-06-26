defmodule Expug.Transformer do
  @moduledoc """
  Transforms a node after compilation.
  """

  alias Expug.Visitor

  @doc """
  Transforms a node.
  """
  def transform(node) do
    node
    |> Visitor.visit(&close_statements/1)
  end

  def close_statements(%{type: type, value: value} = node)
  when type == :buffered_text or type == :statement do
    if open?(value) do
      node
      |> Map.put(:close, "end")
    else
      node
    end
  end

  def close_statements(node) do
    node
  end

  def open?(statement) do
    has_do = Regex.run(~r/[^A-Za-z0-9]do\s*$/, statement)
    has_do && true || false
  end
end
