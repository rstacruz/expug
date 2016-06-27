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
    |> Visitor.visit_children(&close_clauses/1)
  end

  @doc """
  Finds out what clauses can follow a given clause.

      iex> Expug.Transformer.clause_after("if")
      ["else"]

      iex> Expug.Transformer.clause_after("try")
      ["catch", "rescue", "after"]

      iex> Expug.Transformer.clause_after("cond")
      [] # nothing can follow cond
  """
  def clause_after("if"), do: ["else"]
  def clause_after("unless"), do: ["else"]
  def clause_after("try"), do: ["catch", "rescue", "after"]
  def clause_after("catch"), do: ["catch", "after"]
  def clause_after("rescue"), do: ["rescue", "after"]
  def clause_after(_), do: []

  @doc """
  Closes all possible clauses in the given `children`.
  """
  def close_clauses(children) do
    {_, children} = close_clause(children, ["if", "unless", "try"])
    children
  end

  @doc """
  Closes all a given `next` clause in the given `children`.

  Returns a tuple of `{status, children}` where `:status` depicts what happened
  on the first node given to it. `:multi` means it was matched for a multi-clause,
  `:single` means it was matched for a single clause, `:ok` otherwise.
  """
  def close_clause([node | children], next) do
    pre = prelude(node)

    cond do
      # it's a multi-clause thing (eg, if-else-end, try-rescue-after-end)
      # See if we're at `if`...
      statement?(node.type) and Enum.member?(next, pre) ->
        # Then check if the next one is `else`...
        case close_clause(children, clause_after(pre)) do
          {:multi, children} ->
            # the next one IS else, don't close and proceed
            {:multi, [node | children]}

          {_, children} ->
            # the next one is not else, so close us up and proceed
            node = node |> Map.put(:close, "end")
            {:multi, [node | close_clauses(children)]}
        end

      # it's a single-clause thing (eg, cond do)
      statement?(node.type) and open?(node.value) ->
        node = node |> Map.put(:close, "end")
        {:single, [node | close_clauses(children)]}

      # Else, just reset the chain
      true ->
        {:ok, [node | close_clauses(children)]}
    end
  end

  def close_clause([], _upcoming) do
    {:ok, []} # The last child is `if`
  end

  def close_clause(children, [] = _upcoming) do
    {:ok, children} # Already closed end, but there's still more
  end

  @doc """
  Get the prelude of a given node

      iex> Expug.Transformer.prelude(%{value: "if foo"})
      "if"

      iex> Expug.Transformer.prelude(%{value: "case derp"})
      "case"

      iex> Expug.Transformer.prelude(%{value: "1 + 2"})
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

  # Checks if a given statement is open.
  defp open?(statement) do
    has_do = Regex.run(~r/[^A-Za-z0-9]do\s*$/, statement)
    has_do && true || false
  end
end
