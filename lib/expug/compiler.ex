defmodule Expug.Compiler do
  @moduledoc """
  Compiles tokens into an AST.

  ## How it works
  Nodes are maps with a `:type` key. They are then filled up using a function
  with the same name as the type:

      node = %{type: :document}
      document({node, tokens})

  This function returns another `{node, tokens}` tuple, where `node` is the
  updated node, and `tokens` are the rest of the tokens to parse.

  The functions (`document/1`) here can do 1 of these things:

  - Spawn a child, say, `%{type: :element}`, then delegate to its function (eg, `element()`).
  - Simply return a `{node, tokens}` - no transformation here.

  The functions `indent()` and `statement()` are a little different. It can
  give you an element, or a text node, or whatever.
  """

  import List, only: [first: 1]

  @doc """
  Compiles tokens. Returns `{:ok, ast}` on success.

  On failure, it returns `{:error, [type: type, position: {line, col}]}`.
  """
  def compile(tokens) do
    tokens = Enum.reverse(tokens)
    node = %{type: :document}

    try do
      {node, _tokens} = document({node, tokens})
      {:ok, node}
    catch {:compile_error, type, {pos, _, _} = _token} ->
      {:error, %{
        type: type,
        position: pos
      }}
    end
  end

  @doc """
  A document.
  """
  def document({node, [{_, :doctype, type} = t | tokens]}) do
    node = Map.put(node, :doctype, %{
      type: :doctype,
      value: type,
      token: t
    })
    indent({node, tokens}, -1)
  end

  def document({node, tokens}) do
    indent({node, tokens}, -1) # optional
  end

  @doc """
  Indentation. Called with `depth` which is the current level its at.
  """
  def indent({_node, [{_, :indent, subdepth}, token | _]}, depth)
  when subdepth < depth do
    throw {:compile_error, :ambiguous_indentation, token}
  end

  # Siblings; stop processing.
  def indent({node, [{_, :indent, subdepth} | _] = tokens}, depth)
  when subdepth == depth do
    {node, tokens}
  end

  # Found children, start a new subtree
  def indent({node, [{_, :indent, subdepth} | tokens]}, depth)
  when subdepth > depth do
    statement({node, tokens}, subdepth)
    |> indent(depth)
  end

  # End of file, no tokens left.
  def indent({node, []}, _depth) do
    {node, []}
  end

  def indent({_node, [token | _]}, _depth) do
    throw {:compile_error, :unexpected_token, token}
  end

  @doc """
  A statement after an `:indent`.
  Can consume these:

      :element_name
      :element_class
      :element_id
      [:attribute_open [...] :attribute_close]
      [:solo_buffered_text | :solo_raw_text]
  """
  def statement({node, [{_, :element_name, _} = t | _] = tokens}, depth) do
    create_element(node, t, tokens, depth)
  end

  def statement({node, [{_, :element_class, _} = t | _] = tokens}, depth) do
    create_element(node, t, tokens, depth)
  end

  def statement({node, [{_, :element_id, _} = t | _] = tokens}, depth) do
    create_element(node, t, tokens, depth)
  end

  def statement({node, [{_, :raw_text, value} = t | tokens]}, _depth) do
    child = %{type: :raw_text, value: value, token: t}
    node = add_child(node, child)
    {node, tokens}
  end

  def statement({node, [{_, :buffered_text, value} = t | tokens]}, _depth) do
    child = %{type: :buffered_text, value: value, token: t}
    node = add_child(node, child)
    {node, tokens}
  end

  def create_element(node, t, tokens, depth) do
    child = %{type: :element, name: "div", token: t}
    {child, rest} = element({child, tokens}, depth)
    node = add_child(node, child)
    {node, rest}
  end

  @doc """
  Parses an element.
  Returns a `%{type: :element}` node.
  """
  def element({node, tokens}, depth) do
    case tokens do
      [{_, :element_name, value} | rest] ->
        node = Map.put(node, :name, value)
        element({node, rest}, depth)

      [{_, :element_id, value} | rest] ->
        attr_list = add_attribute(node[:attributes] || %{}, "id", {:text, value})
        node = Map.put(node, :attributes, attr_list)
        element({node, rest}, depth)

      [{_, :element_class, value} | rest] ->
        attr_list = add_attribute(node[:attributes] || %{}, "class", {:text, value})
        node = Map.put(node, :attributes, attr_list)
        element({node, rest}, depth)

      [{_, :sole_raw_text, value} = t | rest] ->
        # should be in children
        child = %{type: :raw_text, value: value, token: t}
        node = add_child(node, child)
        element({node, rest}, depth)

      [{_, :sole_buffered_text, value} = t | rest] ->
        child = %{type: :buffered_text, value: value, token: t}
        node = add_child(node, child)
        element({node, rest}, depth)

      [{_, :attribute_open, _} | rest] ->
        {attr_list, rest} = attribute({node[:attributes] || %{}, rest})
        node = Map.put(node, :attributes, attr_list)
        {node, rest}

      [{_, :indent, subdepth} | _] = tokens ->
        if subdepth > depth do
           indent({node, tokens}, depth)
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
  def attribute({attr_list, tokens}) do
    case tokens do
      [{_, :attribute_key, key}, {_, :attribute_value, value} | rest] ->
        attr_list = add_attribute(attr_list, key, {:eval, value})
        attribute({attr_list, rest})

      [{_, :attribute_close, _} | rest] ->
        {attr_list, rest}

      rest ->
        throw {:compile_error, :unexpected_token, first(rest)}
    end
  end

  def add_attribute(list, key, value) do
    Map.update(list, key, [value], &(&1 ++ [value]))
  end

  @doc """
  Adds a child to a Node.

      iex> Expug.Compiler.add_child(%{}, %{type: :a})
      %{children: [%{type: :a}]}

      iex> src = %{children: [%{type: :a}]}
      ...> Expug.Compiler.add_child(src, %{type: :b})
      %{children: [%{type: :a}, %{type: :b}]}
  """
  def add_child(node, child) do
    Map.update(node, :children, [child], &(&1 ++ [child]))
  end
end
