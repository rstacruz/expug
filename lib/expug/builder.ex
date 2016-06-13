defmodule Expug.Builder do
  require Logger

  def build(ast) do
    {:ok, make(ast)}
  end

  def make(nil) do
    ""
  end

  def make(%{type: :document} = node) do
    "" <>
      make(node[:doctype]) <>
      children(node[:children])
  end

  def make(%{type: :doctype, value: "html5"}) do
    "<!doctype html>\n"
  end

  def make(%{type: :doctype, value: "xml"}) do
    ~s(<?xml version="1.0" encoding="utf-8" ?>\n)
  end

  def make(%{type: :doctype, value: value}) do
    "<!doctype #{value}>\n"
  end

  @doc """
  Builds elements
  """
  def make(%{type: :element} = node) do
    "" <>
      "<" <> node[:name] <>
      ">\n" <>
      make(node[:text]) <>
      children(node[:children]) <>
      "</" <> node[:name] <> ">\n"
  end

  @doc """
  Builds text
  """
  def make(%{type: :raw_text, value: value}) do
    "#{value}\n"
  end

  def make(%{type: :buffered_text, value: value}) do
    "<%= #{value} %>\n"
  end

  def make(%{type: :unescaped_text, value: value}) do
    "<%= #{value} %>\n"
  end

  def children(nil) do
    ""
  end

  def children(list) do
    Enum.reduce list, "", fn item, result ->
      result <> make(item)
    end
  end
end
