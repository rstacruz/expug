defmodule Exslim.Compiler do
  @moduledoc """
  Compiles tokens into an AST.
  """

  alias Keyword, as: K

  def compile(tokens) do
    tokens = Enum.reverse(tokens)
    node = [type: :document]
    {node, _tokens} = {node, tokens} |> doctype()
    {:ok, node}
  end

  def doctype({node, tokens}) do
    case tokens do
      [{_, :doctype, type} | rest] ->
        node = K.put(node, :doctype, type)
        statements({node, rest}, -1)

      [] ->
        {node, []}

      _ ->
        statements({node, tokens}, -1) # optional
    end
  end

  def statements({node, tokens}, indent) do
    # :element_name
    # :element_class
    # :element_id
    # [:attribute_open [...] :attribute_close]
    # [:solo_buffered_text | :solo_raw_text]
    case tokens do
      [{_, :indent, ^indent} | _] ->
        {node, []} # siblings, stop processing

      [{_, :indent, subindent} | tokens = [{_, :element_name, _} | _]] ->
        {child, rest} = element({[type: :element], tokens}, subindent)
        node = K.update(node, :children, [child], &(&1 ++ [child]))
        statements({node, rest}, indent)

      [] ->
        {node, []} # end of file

      rest ->
        # extra tokens left over
        throw {:compile_error, rest}
    end
  end

  def element({node, tokens}, indent) do
    case tokens do
      [{_, :element_name, value} | rest] ->
        node = K.put(node, :name, value)
        element({node, rest}, indent)

      [{_, :element_id, value} | rest] ->
        node = K.put(node, :id, value)
        element({node, rest}, indent)

      [{_, :element_class, value} | rest] ->
        node = K.update(node, :class, [value], &(&1 ++ [value]))
        element({node, rest}, indent)

      [{_, :sole_raw_text, value} | rest] ->
        node = K.put(node, :text, [type: :raw_text, value: value])
        element({node, rest}, indent)

      [{_, :sole_buffered_text, value} | rest] ->
        node = K.put(node, :text, [type: :buffered_text, value: value])
        element({node, rest}, indent)

      [{_, :indent, subindent} | _] = tokens ->
        if subindent > indent do
           statements({node, tokens}, indent)
        else
          {node, tokens}
        end

      [] ->
        {node, []}
    end
  end
end
