defmodule Exslim.Compiler do
  @moduledoc """
  Compiles tokens into an AST.
  """

  def compile(tokens) do
    tokens = Enum.reverse(tokens)
    root = [type: :document]
    {root, tokens} =
    {root, tokens}
    |> doctype()
    {:ok, root}
  end

  def doctype({root, [{_, :doctype, type} | rest ]}) do
    { [{:doctype, type} | root], rest }
  end

  def doctype({root, tokens}) do
    {root, tokens} # optional
  end
end
