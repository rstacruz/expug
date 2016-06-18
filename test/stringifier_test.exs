defmodule StringifierTest do
  use ExUnit.Case

  def build(source) do
    with \
      tokens <- Expug.Tokenizer.tokenize(source),
      ast <- Expug.Compiler.compile(tokens),
      lines <- Expug.Builder.build(ast) do
      Expug.Stringifier.stringify(lines)
    end
  end

  test "nesting" do
    eex = build("""
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
    eex = build("""
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
    eex = build("""
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
    eex = build("""
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
    eex = build("""
    div.foo(class="bar")
    """)

    assert eex == ~S"""
    <div class=<%= raw(Expug.Runtime.attr_value(Enum.join(["foo", "bar"], " "))) %>></div>
    """
  end

  test "joining IDs" do
    eex = build("""
    div#a#b
    """)

    assert eex == ~S"""
    <div id=<%= raw(Expug.Runtime.attr_value(Enum.join(["a", "b"], " "))) %>></div>
    """
  end

  test "extra depths" do
    eex = build("""
    div(role="hi"
    )

    div
    """)

    assert eex == ~S"""
    <div role=<%= raw(Expug.Runtime.attr_value("hi")) %>></div>
    <%

    %><div></div>
    """
  end

  test "new line attributes" do
    eex = build("""
    div(role="hi"
    id="foo")
    """)

    assert eex == ~S"""
    <div id=<%= raw(Expug.Runtime.attr_value("foo")) %> role=<%= raw(Expug.Runtime.attr_value("hi")) %>></div>
    """
  end

  test "colon in attributes" do
    eex = build("""
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

  @tag :pending
  test "! (throw a proper error)"
end
