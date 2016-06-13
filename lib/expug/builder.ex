defmodule Expug.Builder do
  @moduledoc ~S"""
  Builds lines from an AST.

      iex> source = "div\n  | Hello"
      iex> with {:ok, tokens} <- Expug.Tokenizer.tokenize(source),
      ...>      {:ok, ast} <- Expug.Compiler.compile(tokens),
      ...>      {:ok, lines} <- Expug.Builder.build(ast),
      ...>   do: lines
      %{
        :lines => 2,
        1 => ["<div>"],
        2 => ["Hello", "</div>"]
      }

  This gives you a map of lines that the `Stringifier` will work on.
  """

  require Logger

  def build(ast) do
    {:ok, %{lines: 0} |> make(ast)}
  end

  @doc """
  Builds elements.
  """
  def make(doc, %{type: :document} = node) do
    doc
    |> make(node[:doctype])
    |> children(node[:children])
  end

  def make(doc, %{type: :doctype, value: "html5"} = node) do
    doc
    |> put(node, "<!doctype html>")
  end

  def make(doc, %{type: :doctype, value: "xml"} = node) do
    doc
    |> put(node, ~s(<?xml version="1.0" encoding="utf-8" ?>))
  end

  def make(doc, %{type: :doctype, value: value} = node) do
    doc
    |> put(node, "<!doctype #{value}>")
  end

  @doc """
  Builds elements.
  """
  def make(doc, %{type: :element} = node) do
    doc
    |> put(node, "<" <> node[:name] <> ">")
    |> make(node[:text])
    |> children(node[:children])
    |> put_last("</" <> node[:name] <> ">") # wrong
  end

  @doc """
  Builds text.
  """
  def make(doc, %{type: :raw_text, value: value} = node) do
    doc
    |> put(node, "#{value}")
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
