defmodule Expug.Builder do
  require Logger

  def build(ast) do
    {:ok, document(ast)}
  end

  def document(node) do
    "" <>
      doctype(node[:doctype]) <>
      children(node[:children])
  end

  def doctype(%{ value: value }) do
    "<!doctype #{value}>\n"
  end

  def doctype(_) do
    ""
  end

  def children(nil) do
    ""
  end

  def children(list) do
    Enum.reduce list, "", fn item, result ->
      result <> element(item)
    end
  end

  def element(node) do
    "" <>
      "<" <> node[:name] <>
      ">\n" <>
      text(node[:text]) <>
      children(node[:children]) <>
      "</" <> node[:name] <> ">\n"
  end

  def text(%{type: :raw_text, value: value}) do
    "#{value}\n"
  end

  def text(%{type: :buffered_text, value: value}) do
    "<%= #{value} %>\n"
  end

  def text(%{type: :unescaped_text, value: value}) do
    "<%= #{value} %>\n"
  end

  def text(_) do
    ""
  end
end
