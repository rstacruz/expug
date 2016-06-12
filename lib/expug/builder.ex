defmodule Expug.Builder do
  def build(ast) do
    {:ok, document(ast)}
  end

  def document(node) do
    result = ""
    if node[:doctype] do
      result = result <> "<!doctype #{node[:doctype]}>"
    end

    if node[:children] do
      result = result <> children(node[:children])
    end
    result
  end

  def children(list) do
    Enum.reduce list, "", fn item, result ->
      result <> element(item)
    end
  end

  def element(node) do
    result = ""
    result = result <> "<" <> node[:name]
    result = result <> ">"

    if node[:text] do
      result = result <> text(node[:text])
    end

    if node[:children] do
      result = result <> children(node[:children])
    end

    result = result <> "</" <> node[:name] <> ">"
    result
  end

  def text([type: :raw_text, value: value]) do
    value
  end

  def text([type: :buffered_text, value: value]) do
    "<%= #{value} %>"
  end

  def text([type: :unescaped_text, value: value]) do
    "<%= #{value} %>"
  end
end