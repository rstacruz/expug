defmodule Expug.Builder do
  @moduledoc ~S"""
  Builds lines from an AST.

      iex> source = "div\n  | Hello"
      iex> with tokens <- Expug.Tokenizer.tokenize(source),
      ...>      ast <- Expug.Compiler.compile(tokens),
      ...>      lines <- Expug.Builder.build(ast),
      ...>   do: lines
      %{
        :lines => 2,
        1 => ["<div>"],
        2 => ["Hello", "</div>"]
      }

  This gives you a map of lines that the `Stringifier` will work on.

  ## Also see
  - `Expug.Compiler` builds the AST used by this builder.
  - `Expug.Stringifier` takes this builder's output.
  """

  require Logger

  # See: http://www.w3.org/TR/html5/syntax.html#void-elements
  @void_elements ["area", "base", "br", "col", "embed", "hr", "img", "input",
   "keygen", "link", "meta", "param", "source", "track", "wbr"]

  @defaults %{
    attr_helper: "Expug.Runtime.attr",
    raw_helper: "raw"
  }

  def build(ast, opts \\ []) do
    opts = Enum.into(opts, @defaults)

    %{lines: 0, options: opts, doctype: nil}
    |> make(ast)
    |> Map.delete(:options)
  end

  @doc """
  Builds elements.
  """
  def make(doc, %{type: :document} = node) do
    doc
    |> Map.put(:doctype, :html)
    |> make(node[:doctype])
    |> children(node[:children])
    |> Map.delete(:doctype)
  end

  def make(doc, %{type: :doctype, value: "html5"} = node) do
    doc
    |> put(node, "<!doctype html>")
  end

  def make(doc, %{type: :doctype, value: "xml"} = node) do
    doc
    |> Map.put(:doctype, :xml)
    |> put(node, ~s(<?xml version="1.0" encoding="utf-8" ?>))
  end

  def make(doc, %{type: :doctype, value: value} = node) do
    doc
    |> put(node, "<!doctype #{value}>")
  end

  @doc """
  Builds elements.
  """
  def make(doc, %{type: :element, children: list} = node) do
    doc
    |> put(node, element(doc, node))
    |> children(list)
    |> put_last("</" <> node[:name] <> ">")
  end

  def make(doc, %{type: :element} = node) do
    doc
    |> put(node, self_closing_element(doc, node))
  end

  def make(doc, %{type: :statement, value: value, children: [_|_] = list} = node) do
    doc
    |> put(node, "<% #{value} %>")
    |> put_collapse(node)
    |> children(list)
    |> add_closing(node)
  end

  def make(doc, %{type: :statement, value: value} = node) do
    doc
    |> put(node, "<% #{value} %>")
  end

  @doc """
  Builds text.
  """
  def make(doc, %{type: :raw_text, value: value} = node) do
    doc
    |> put(node, "#{value}")
  end

  def make(doc, %{type: :buffered_text, value: value, children: [_|_] = list} = node) do
    doc
    |> put(node, "<%= #{value} %>")
    |> put_collapse(node)
    |> children(list)
    |> add_closing(node)
  end

  def make(doc, %{type: :buffered_text, value: value} = node) do
    doc
    |> put(node, "<%= #{value} %>")
  end

  # Handle `!= for item <- list do` (has children)
  def make(doc, %{type: :unescaped_text, value: value, children: [_|_] = list} = node) do
    %{options: %{raw_helper: raw}} = doc
    doc
    |> put(node, "<%= #{raw}(#{value} %>")
    |> put_collapse(node)
    |> children(list)
    |> add_closing(node, ")")
  end

  # Handle `!= @hello`
  def make(doc, %{type: :unescaped_text, value: value} = node) do
    %{options: %{raw_helper: raw}} = doc
    case node[:open] do
      true ->
        doc
        |> put(node, "<%= #{raw}(#{value} %>")
      _ ->
        doc
        |> put(node, "<%= #{raw}(#{value}) %>")
    end
  end

  def make(doc, %{type: :block_text, value: value} = node) do
    doc
    |> put(node, value)
  end

  def make(doc, nil) do
    doc
  end

  def make(_doc, %{type: type, token: {position, _, _}}) do
    throw %{
      type: :cant_build_node,
      node_type: type,
      position: position
    }
  end

  def add_closing(doc, node, suffix \\ "")
  def add_closing(doc, %{close: close}, suffix) do
    doc
    |> put_last_no_space("<% #{close}#{suffix} %>")
  end

  def add_closing(doc, _, _), do: doc

  @doc """
  Builds a list of nodes.
  """
  def children(doc, nil) do
    doc
  end

  def children(doc, list) do
    Enum.reduce list, doc, fn node, doc ->
      make(doc, node)
    end
  end

  @doc """
  Builds an element opening tag.
  """

  def element(doc, node) do
    "<" <> node[:name] <> attributes(doc, node[:attributes]) <> ">"
  end

  def self_closing_element(doc, node) do
    tag = node[:name] <> attributes(doc, node[:attributes])
    cond do
      doc[:doctype] == :xml ->
        "<#{tag} />"
      self_closable?(node) ->
        "<#{tag}>"
      true ->
        "<#{tag}></#{node[:name]}>"
    end
  end

  def self_closable?(node) do
    Enum.any?(@void_elements, &(&1 == node[:name])) && true
  end

  @doc ~S"""
  Stringifies an attributes map.

      iex> doc = %{options: %{}}
      iex> Expug.Builder.attributes(doc, %{ "src" => [{:text, "image.jpg"}] })
      " src=\"image.jpg\""

      #iex> doc = %{options: %{}}
      #iex> Expug.Builder.attributes(doc, %{ "class" => [{:text, "a"}, {:text, "b"}] })
      #" class=\"a b\""

      iex> doc = %{options: %{attr_helper: "attr", raw_helper: "raw"}}
      iex> Expug.Builder.attributes(doc, %{ "src" => [{:eval, "@image"}] })
      "<%= raw(attr(\"src\", @image)) %>"

      iex> doc = %{options: %{attr_helper: "attr", raw_helper: "raw"}}
      iex> Expug.Builder.attributes(doc, %{ "class" => [{:eval, "@a"}, {:eval, "@b"}] })
      "<%= raw(attr(\"class\", Enum.join([@a, @b], \" \"))) %>"
  """
  def attributes(_doc, nil), do: ""

  def attributes(doc, %{} = attributes) do
    Enum.reduce attributes, "", fn {key, values}, acc ->
      acc <> valueify(doc, key, values)
    end
  end

  def valueify(doc, key, [{:eval, value}]) do
    %{options: %{attr_helper: attr, raw_helper: raw}} = doc
    "<%= #{raw}(#{attr}(#{inspect(key)}, #{value})) %>"
  end

  def valueify(_doc, key, [{:text, value}]) do
    Expug.Runtime.attr(key, value)
  end

  def valueify(doc, key, values) when length(values) > 1 do
    %{options: %{attr_helper: attr, raw_helper: raw}} = doc
    inside = Enum.reduce values, "", fn
      {:eval, value}, acc ->
        acc |> str_join(value, ", ")
      {:text, value}, acc ->
        acc |> str_join(Expug.Runtime.attr_value(value), ", ")
    end

    "<%= #{raw}(#{attr}(#{inspect(key)}, Enum.join([#{inside}], \" \"))) %>"
  end

  def str_join(left, str, sep \\ " ")
  def str_join("", str, _sep), do: str
  def str_join(left, str, sep), do: left <> sep <> str

  @doc """
  Adds a line based on a token's location.
  """
  def put(%{lines: max} = doc, %{token: {{line, _col}, _, _}}, str) do
    doc
    |> update_line_count(line, max)
    |> Map.update(line, [str], &(&1 ++ [str]))
  end

  @doc """
  Adds a line to the end of a document.
  Used for closing tags.
  """
  def put_last(%{lines: line} = doc, str) do
    doc
    |> Map.update(line, [str], &(&1 ++ [str]))
  end

  @doc """
  Puts a collapser on the lane after the given token.
  Used for if...end statements.
  """
  def put_collapse(%{lines: max} = doc, %{token: {{line, _col}, _, _}}) do
    doc
    |> update_line_count(line + 1, max)
    |> Map.update(line + 1, [:collapse], &(&1 ++ [:collapse]))
  end

  @doc """
  Adds a line to the end of a document, but without a newline before it.
  Used for closing `<% end %>`.
  """
  def put_last_no_space(%{lines: line} = doc, str) do
    doc
    |> Map.update(line, [str], fn segments ->
      List.update_at(segments, -1, &(&1 <> str))
    end)
  end

  @doc """
  Updates the `:lines` count if the latest line is beyond the current max.
  """
  def update_line_count(doc, line, max) when line > max do
    Map.put(doc, :lines, line)
  end

  def update_line_count(doc, _line, _max) do
    doc
  end
end
