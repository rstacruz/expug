defmodule Expug.Builder do
  @moduledoc """
  Builds lines from an AST.
  """

  require Logger

  def build(ast) do
    {:ok, %{} |> make(ast)}
  end

  def make(doc, nil) do
    doc
  end

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
  Builds elements
  """
  def make(doc, %{type: :element} = node) do
    doc
    |> put(node, "<" <> node[:name] <> ">")
    |> make(node[:text])
    |> children(node[:children])
    |> put_last("</" <> node[:name] <> ">") # wrong
  end

  @doc """
  Builds text
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
    |> put(node, "<%= #{value} %>")
  end

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
  def put(doc, %{token: {{line, _col}, _, _}}, str) do
    doc
    |> Map.update(line, [str], &(&1 ++ [str]))
  end

  @doc """
  Adds a line to the end of a document.
  """
  def put_last(doc, str) do
    {line, _} = Map.to_list(doc) |> List.last()
    doc
    |> Map.update(line, [str], &(&1 ++ [str]))
  end
end
