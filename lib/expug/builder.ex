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

  @self_closable ["meta", "img", "link"]

  def build(ast, _opts \\ []) do
    %{lines: 0} |> make(ast)
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
    |> children(list)
    |> put_last_no_space("<% end %>")
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
    |> children(list)
    |> put_last_no_space("<% end %>")
  end

  def make(doc, %{type: :buffered_text, value: value} = node) do
    doc
    |> put(node, "<%= #{value} %>")
  end

  def make(doc, %{type: :unescaped_text, value: value} = node) do
    doc
    |> put(node, "<%= raw(#{value}) %>")
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

  def element(_doc, node) do
    "<" <> node[:name] <> attributes(node[:attributes]) <> ">"
  end

  def self_closing_element(doc, node) do
    tag = node[:name] <> attributes(node[:attributes])
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
    Enum.any?(@self_closable, &(&1 == node[:name])) && true
  end

  @doc ~S"""
  Stringifies an attributes map.

      iex> Expug.Builder.attributes(%{ "src" => [{:text, "image.jpg"}] })
      " src=\"image.jpg\""

      #iex> Expug.Builder.attributes(%{ "class" => [{:text, "a"}, {:text, "b"}] })
      #" class=\"a b\""

      iex> Expug.Builder.attributes(%{ "src" => [{:eval, "@image"}] })
      "<%= raw(Expug.Runtime.attr(\"src\", @image)) %>"

      iex> Expug.Builder.attributes(%{ "class" => [{:eval, "@a"}, {:eval, "@b"}] })
      "<%= raw(Expug.Runtime.attr(\"class\", Enum.join([@a, @b], \" \"))) %>"
  """
  def attributes(nil), do: ""

  def attributes(%{} = attributes) do
    Enum.reduce attributes, "", fn {key, values}, acc ->
      acc <> valueify(key, values)
    end
  end

  def valueify(key, [{:eval, value}]) do
    "<%= raw(Expug.Runtime.attr(#{inspect(key)}, #{value})) %>"
  end

  def valueify(key, [{:text, value}]) do
    Expug.Runtime.attr(key, value)
  end

  def valueify(key, values) when length(values) > 1 do
    inside = Enum.reduce values, "", fn
      {:eval, value}, acc ->
        acc |> str_join(value, ", ")
      {:text, value}, acc ->
        acc |> str_join(Expug.Runtime.attr_value(value), ", ")
    end

    "<%= raw(Expug.Runtime.attr(#{inspect(key)}, Enum.join([#{inside}], \" \"))) %>"
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
  """
  def put_last(%{lines: line} = doc, str) do
    doc
    |> Map.update(line, [str], &(&1 ++ [str]))
  end

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
