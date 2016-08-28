defmodule StringifierTest do
  use ExUnit.Case

  def build(source) do
    source
    |> Expug.Tokenizer.tokenize()
    |> Expug.Compiler.compile()
    |> Expug.Builder.build()
    |> Expug.Stringifier.stringify()
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
    <div<%= raw(Expug.Runtime.attr("class", Enum.join(["foo", "bar"], " "))) %>></div>
    """
  end

  test "joining IDs" do
    eex = build("""
    div#a#b
    """)

    assert eex == ~S"""
    <div<%= raw(Expug.Runtime.attr("id", Enum.join(["a", "b"], " "))) %>></div>
    """
  end

  test "extra depths" do
    eex = build("""
    div(role="hi"
    )

    div
    """)

    assert eex == ~S"""
    <div<%= raw(Expug.Runtime.attr("role", "hi")) %>></div>
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
    <div<%= raw(Expug.Runtime.attr("id", "foo")) %><%= raw(Expug.Runtime.attr("role", "hi")) %>></div>
    """
  end

  test "colon in attributes" do
    eex = build("""
    div(svg:src="hi")
    """)

    assert eex == ~S"""
    <div<%= raw(Expug.Runtime.attr("svg:src", "hi")) %>></div>
    """
  end

  test "collapsing" do
    eex = build("""
    = if @foo do
      div
    """)

    assert eex == """
    <%= if @foo do %><%
    %><div></div><% end %>
    """
  end

  test "empty strings" do
    eex = build("")

    assert eex == ""
  end

  test "empty space attributes" do
    eex = build("div( )")

    assert eex == "<div></div>\n"
  end

  @tag :pending
  test "illegal nesting inside |" do
    eex = build("""
    | hi
      foo
    """)

    assert eex == ""
  end

  @tag :pending
  test "-// comment nesting"

  test "script." do
    eex = build("""
    script.
      alert("hi")
    """)

    assert eex == ~S"""
    <script>
    alert("hi")<%= "\n" %></script>
    """
  end

  test "script. multiline" do
    eex = build("""
    script.
      alert("hi")
      alert("hello")
      alert("hola")
    """)

    assert eex == ~S"""
    <script>
    alert("hi")
    alert("hello")
    alert("hola")<%= "\n" %></script>
    """
  end

  @tag :pending
  test "ul: li: button Hello"

  test "multiline" do
    eex = build("""
    - render(
      @conn)
    div
    """)

    assert eex == ~S"""
    <% render(
      @conn) %>
    <div></div>
    """
  end

  test "multiline =" do
    eex = build("""
    = render(
      @conn)
    div
    """)

    assert eex == ~S"""
    <%= render(
      @conn) %>
    <div></div>
    """
  end
end
