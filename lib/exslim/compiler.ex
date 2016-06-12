defmodule Exslim.Compiler do
  @moduledoc """
  Compiles tokens into an AST.
  """

  alias Keyword, as: K
  import List, only: [first: 1]

  def compile(tokens) do
    tokens = Enum.reverse(tokens)
    node = [type: :document]

    try do
      {node, _tokens} = {node, tokens} |> doctype()
      {:ok, node}
    catch {:compile_error, err, token} ->
      {:error, err, token}
    end
  end

  def doctype({node, tokens}) do
    case tokens do
      [{_, :doctype, type} | rest] ->
        node = K.put(node, :doctype, type)
        statements({node, rest}, -1)

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
      [{_, :indent, ^indent} | _] = tokens ->
        {node, tokens} # siblings, stop processing

      [{_, :indent, subindent} | tokens = [{_, :element_name, _} | _]] ->
        if subindent < indent do
          throw {:compile_error, :ambiguous_indentation, first(tokens)}
        end
        {child, rest} = element({[type: :element], tokens}, subindent)
        node = K.update(node, :children, [child], &(&1 ++ [child]))
        statements({node, rest}, indent)

      [] ->
        {node, []} # end of file

      rest ->
        # extra tokens left over
        throw {:compile_error, :unexpected_token, first(rest)}
    end
  end

  @doc """
  Parses an element.
  Returns a `[type: :element]` node.
  """
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

      [{_, :attribute_open, _} | rest] ->
        {attr_list, rest} = attributes({node[:attributes] || [], rest})
        node = K.put(node, :attributes, attr_list)
        {node, rest}

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

  @doc """
  Returns a list of `[type: :attribute]` items.
  """
  def attributes({attr_list, tokens}) do
    case tokens do
      [{_, :attribute_key, key}, {_, :attribute_value, value} | rest] ->
        attr_list = attr_list ++ [ [type: :attribute, key: key, val: value] ]
        attributes({attr_list, rest})

      [{_, :attribute_close, _} | rest] ->
        {attr_list, rest}

      rest ->
        throw {:compile_error, :unexpected_token, first(rest)}
    end
  end
end
