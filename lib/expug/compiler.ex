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

  ## Also see
  - `Expug.Tokenizer` is used to build the tokens used by this compiler.
  - `Expug.Builder` uses the AST made by this compiler.
  """

  require Logger

  @doc """
  Compiles tokens. Returns `{:ok, ast}` on success.

  On failure, it returns `{:error, [type: type, position: {line, col}]}`.
  """
  def compile(tokens, _opts \\ []) do
    tokens = Enum.reverse(tokens)
    node = %{type: :document}

    try do
      {node, _tokens} = document({node, tokens})
      node = Expug.Transformer.transform(node)
      node
    catch
      {:compile_error, type, [{pos, token, _} | _]} ->
        # TODO: create an EOF token
        throw %{ type: type, position: pos, token_type: token }
      {:compile_error, type, []} ->
        throw %{ type: type }
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
    indent({node, tokens}, [0])
  end

  def document({node, tokens}) do
    indent({node, tokens}, [0]) # optional
  end

  @doc """
  Indentation. Called with `depth` which is the current level its at.
  """
  def indent({node, [{_, :indent, subdepth} | [_|_] = tokens]}, [d | _] = depths)
  when subdepth > d do
    # Found children, start a new subtree.
    [child | rest] = Enum.reverse(node[:children] || [])
    {child, tokens} = statement({child, tokens}, [ subdepth | depths ])
    |> indent([ subdepth | depths ])

    # Go back to our tree.
    children = Enum.reverse([child | rest])
    node = Map.put(node, :children, children)
    {node, tokens}
    |> indent(depths)
  end

  def indent({node, [{_, :indent, subdepth} | [_|_] = tokens]}, [d | _] = depths)
  when subdepth == d do
    {node, tokens}
    |> statement(depths)
    |> indent(depths)
  end

  def indent({node, [{_, :indent, subdepth} | [_|_]] = tokens}, [d | _])
  when subdepth < d do
    # throw {:compile_error, :ambiguous_indentation, token}
    {node, tokens}
  end

  # End of file, no tokens left.
  def indent({node, []}, _depth) do
    {node, []}
  end

  def indent({_node, tokens}, _depth) do
    throw {:compile_error, :unexpected_token, tokens}
  end

  @doc """
  A statement after an `:indent`.
  Can consume these:

      :element_name
      :element_class
      :element_id
      [:attribute_open [...] :attribute_close]
      [:buffered_text | :unescaped_text | :raw_text | :block_text]
  """
  def statement({node, [{_, :line_comment, _} | [{_, :subindent, _} | _] = tokens]}, _depths) do
    # Pretend to be an element and capture stuff into it; discard it afterwards.
    # This is wrong anyway; it should be tokenized differently.
    subindent({node, tokens})
  end

  def statement({node, [{_, :line_comment, _} | tokens]}, _depths) do
    {node, tokens}
  end

  def statement({node, [{_, :html_comment, value} = t | tokens]}, depths) do
    child = %{type: :html_comment, value: value, token: t}
    {child, tokens} = html_comment({child, tokens})
    node = add_child(node, child)
    {node, tokens}
  end

  def statement({node, [{_, :element_name, _} = t | _] = tokens}, depths) do
    add_element(node, t, tokens, depths)
  end

  def statement({node, [{_, :element_class, _} = t | _] = tokens}, depths) do
    add_element(node, t, tokens, depths)
  end

  def statement({node, [{_, :element_id, _} = t | _] = tokens}, depths) do
    add_element(node, t, tokens, depths)
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

  def statement({node, [{_, :unescaped_text, value} = t | tokens]}, _depth) do
    child = %{type: :unescaped_text, value: value, token: t}
    node = add_child(node, child)
    {node, tokens}
  end

  def statement({node, [{_, :statement, value} = t | tokens]}, _depth) do
    child = %{type: :statement, value: value, token: t}
    node = add_child(node, child)
    {node, tokens}
  end

  def statement({_node, tokens}, _depths) do
     throw {:compile_error, :unexpected_token, tokens}
  end

  def html_comment({node, [{_, :subindent, value} | tokens]}) do
    node = node
    |> Map.update(:value, value, &(&1 <> "\n#{value}"))
    {node, tokens}
    |> html_comment()
  end

  def html_comment({node, tokens}) do
    {node, tokens}
  end

  def add_element(node, t, tokens, depth) do
    child = %{type: :element, name: "div", token: t}
    {child, rest} = element({child, tokens}, node, depth)
    node = add_child(node, child)
    {node, rest}
  end

  @doc """
  Parses an element.
  Returns a `%{type: :element}` node.
  """
  def element({node, tokens}, parent, depths) do
    case tokens do
      [{_, :element_name, value} | rest] ->
        node = Map.put(node, :name, value)
        element({node, rest}, parent, depths)

      [{_, :element_id, value} | rest] ->
        attr_list = add_attribute(node[:attributes] || %{}, "id", {:text, value})
        node = Map.put(node, :attributes, attr_list)
        element({node, rest}, parent, depths)

      [{_, :element_class, value} | rest] ->
        attr_list = add_attribute(node[:attributes] || %{}, "class", {:text, value})
        node = Map.put(node, :attributes, attr_list)
        element({node, rest}, parent, depths)

      [{_, :raw_text, value} = t | rest] ->
        # should be in children
        child = %{type: :raw_text, value: value, token: t}
        node = add_child(node, child)
        element({node, rest}, parent, depths)

      [{_, :buffered_text, value} = t | rest] ->
        child = %{type: :buffered_text, value: value, token: t}
        node = add_child(node, child)
        element({node, rest}, parent, depths)

      [{_, :unescaped_text, value} = t | rest] ->
        child = %{type: :unescaped_text, value: value, token: t}
        node = add_child(node, child)
        element({node, rest}, parent, depths)

      [{_, :block_text, _} | rest] ->
        t = hd(rest)
        {rest, lines} = subindent_capture(rest)
        child = %{type: :block_text, value: lines, token: t}
        node = add_child(node, child)
        element({node, rest}, parent, depths)

      [{_, :attribute_open, _} | rest] ->
        {attr_list, rest} = attribute({node[:attributes] || %{}, rest})
        node = Map.put(node, :attributes, attr_list)
        element({node, rest}, parent, depths)

      tokens ->
        {node, tokens}
    end
  end

  @doc """
  Returns a list of `[type: :attribute]` items.
  """
  def attribute({attr_list, tokens}) do
    case tokens do
      [{_, :attribute_key, key}, {_, :attribute_value, value} | rest] ->
        attr_list = add_attribute(attr_list, key, {:eval, value})
        {attr_list, rest}
        |> attribute()

      [{_, :attribute_key, key} | rest] ->
        attr_list = add_attribute(attr_list, key, {:eval, true})
        {attr_list, rest}
        |> attribute()

      [{_, :attribute_close, _} | rest] ->
        {attr_list, rest}

      rest ->
        {attr_list, rest}
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

  @doc """
  Matches `:subindent` tokens and discards them. Used for line comments (`-#`).
  """
  def subindent({node, [{_, :subindent, _} | rest]}) do
    subindent({node, rest})
  end

  def subindent({node, rest}) do
     {node, rest}
  end

  def subindent_capture(tokens, lines \\ [])
  def subindent_capture([{_, :subindent, line} | rest], lines) do
    lines = lines ++ line
    subindent_capture(rest, lines)
  end

  def subindent_capture(rest, lines) do
    {rest, lines}
  end
end
