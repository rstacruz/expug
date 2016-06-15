defmodule StringifierTest do
  use ExUnit.Case

  def build(source) do
    {:ok, tokens} = Expug.Tokenizer.tokenize(source)
    {:ok, ast} = Expug.Compiler.compile(tokens)
    {:ok, lines} = Expug.Builder.build(ast)
    Expug.Stringifier.stringify(lines)
  end

  test "nesting" do
    {:ok, eex} = build("""
    doctype html
    div
      span= @hello
    """)

    assert eex == ~S"""
    <!doctype html>
    <div>
    <span><%= "\n" %><%= @hello %><%= "\n" %></span><%= "\n" %></div>
    """
  end

  test "with extra lines" do
    {:ok, eex} = build("""
    doctype html


    div
      span= @hello
    """)

    assert eex == ~S"""
    <!doctype html>
    <%

    %><div>
    <span><%= "\n" %><%= @hello %><%= "\n" %></span><%= "\n" %></div>
    """
  end

  test "with extra lines, 2" do
    {:ok, eex} = build("""
    doctype html

    div

      span= @hello
    """)

    assert eex == ~S"""
    <!doctype html>
    <%
    %><div>
    <%
    %><span><%= "\n" %><%= @hello %><%= "\n" %></span><%= "\n" %></div>
    """
  end

  test "indentation magic" do
    {:ok, eex} = build("""
    div
      h1
        span
          a.foo
            | Hello
    """)
    assert eex == ~S"""
    <div>
    <h1>
    <span>
    <a class="foo">
    Hello<%= "\n" %></a><%= "\n" %></span><%= "\n" %></h1><%= "\n" %></div>
    """
  end

  test "joining classes" do
    {:ok, eex} = build("""
    div.foo(class="bar")
    """)

    assert eex == ~S"""
    <div class=<%= raw(Expug.Runtime.attr_value(Enum.join(["foo", "bar"], " "))) %>></div>
    """
  end

  test "joining IDs" do
    {:ok, eex} = build("""
    div#a#b
    """)

    assert eex == ~S"""
    <div id=<%= raw(Expug.Runtime.attr_value(Enum.join(["a", "b"], " "))) %>></div>
    """
  end

  @tag :pending
  test "extra depths" do
    {:ok, eex} = build("""
    div(role="hi"
    )

    div
    """)

    assert eex == ~S"""
    <div role=<%= raw(Expug.Runtime.attr_value("hi"
    )) %>></div>
    <%
    %><div></div>
    """
  end

  @tag :pending
  test "new line attributes" do
    {:ok, eex} = build("""
    div(role="hi"
    id="foo")
    """)

    assert eex == ~S"""
    <div id=<%= raw(Expug.Runtime.attr_value("foo")) %> role=<%= raw(Expug.Runtime.attr_value("hi"
    )) %>></div>
    """
  end

  @tag :pending
  test "colon in attributes" do
    {:ok, eex} = build("""
    div(svg:src="hi")
    """)

    assert eex == ~S"""
    <div svg:src=<%= raw(Expug.Runtime.attr_value("hi")) %>></div>
    """
  end

  @tag :pending
  test "-// comment nesting"

  @tag :pending
  test "script."

  @tag :pending
  test "ul: li: button Hello"
end
