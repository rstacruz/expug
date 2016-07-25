defmodule ExpugCompilerTest do
  use ExUnit.Case

  import Expug.Tokenizer, only: [tokenize: 1]
  import Expug.Compiler, only: [compile: 1]

  doctest Expug.Compiler

  test "doctype only" do
    tokens = tokenize("doctype html5")
    ast = compile(tokens)
    assert %{
      doctype: %{
        type: :doctype,
        value: "html5",
        token: {{1, 9}, :doctype, "html5"}
      },
      type: :document
    } = ast
  end

  test "tag only" do
    tokens = tokenize("div")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        name: "div",
        type: :element
      }]
    } = ast
  end

  test "doctype and tag" do
    tokens = tokenize("doctype html5\ndiv")
    ast = compile(tokens)
    assert %{
      doctype: %{
        type: :doctype,
        value: "html5",
        token: _
      },
      type: :document,
      children: [%{
        name: "div",
        type: :element
      }]
    } = ast
  end

  test "doctype and tag and id" do
    tokens = tokenize("doctype html5\ndiv#box")
    ast = compile(tokens)
    assert %{
      doctype: %{
        type: :doctype,
        value: "html5"
      },
      type: :document,
      children: [%{
        type: :element,
        name: "div",
        attributes: %{
          "id" => [{:text, "box"}]
        }
      }]
  } = ast
  end

  test "tag and classes" do
    tokens = tokenize("div.blue.small")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        name: "div",
        type: :element,
        attributes: %{
          "class" => [{:text, "blue"}, {:text, "small"}]
        }
      }]
    } = ast
  end

  test "buffered text" do
    tokens = tokenize("div= hello")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        name: "div",
        type: :element,
        children: [%{
          type: :buffered_text,
          value: "hello"
        }]
      }]
    } = ast
  end

  test "doctype and tags" do
    tokens = tokenize("doctype html5\ndiv\nspan")
    ast = compile(tokens)
    assert %{
      doctype: %{
        type: :doctype,
        value: "html5",
        token: {{1, 9}, :doctype, "html5"}
      },
      type: :document,
      children: [%{
        name: "div",
        type: :element,
        token: {{2, 1}, :element_name, "div"}
      }, %{
        name: "span",
        type: :element,
        token: {{3, 1}, :element_name, "span"}
      }]
    } == ast
  end

  test "nesting" do
    tokens = tokenize("head\n  title")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        name: "head",
        type: :element,
        children: [%{
          name: "title",
          type: :element
        }]
      }]
    } = ast
  end

  test "nesting deeper" do
    tokens = tokenize("head\n  title\n    span")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        name: "head",
        type: :element,
        children: [%{
          name: "title",
          type: :element,
          children: [%{
            name: "span",
            type: :element
          }]
        }]
      }]
    } = ast
  end

  test "zigzag nesting" do
    tokens = tokenize("head\n  title\n    span\n  meta")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :element,
        name: "head",
        token: {{1, 1}, :element_name, "head"},
        children: [%{
          type: :element,
          name: "title",
          token: {{2, 3}, :element_name, "title"},
          children: [%{
            name: "span",
            type: :element,
            token: {{3, 5}, :element_name, "span"},
          }]
        }, %{
          name: "meta",
          type: :element,
          token: {{4, 3}, :element_name, "meta"},
        }]
      }]
    } == ast
  end

  # test "zigzag nesting error" do
  #   tokens = tokenize("head\n  title\n    span\n meta")
  #   {:error, params} = compile(tokens)
  #   assert params == %{
  #     type: :ambiguous_indentation,
  #     position: {4, 2}
  #   }
  # end

  test "attributes" do
    tokens = tokenize("div(style='color: blue')")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :element,
        name: "div",
        attributes: %{
          "style" => [{:eval, "'color: blue'"}]
        }
      }]
    } = ast
  end

  test "2 attributes" do
    tokens = tokenize("div(id='box' style='color: blue')")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :element,
        name: "div",
        attributes: %{
          "id" => [{:eval, "'box'"}],
          "style" => [{:eval, "'color: blue'"}]
        }
      }]
    } = ast
  end

  test "dupe attributes" do
    tokens = tokenize("div(src=1 src=2)")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :element,
        name: "div",
        attributes: %{
          "src" => [{:eval, "1"}, {:eval, "2"}]
        }
      }]
    } = ast
  end

  test "value-less attributes" do
    tokens = tokenize("div(src)")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :element,
        name: "div",
        attributes: %{
          "src" => [{:eval, true}]
        }
      }]
    } = ast
  end

  test "start with class" do
    tokens = tokenize(".hello")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :element,
        name: "div",
        attributes: %{
          "class" => [{:text, "hello"}]
        }
      }]
    } = ast
  end

  test "start with id" do
    tokens = tokenize("#hello")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :element,
        name: "div",
        attributes: %{
          "id" => [{:text, "hello"}]
        }
      }]
    } = ast
  end

  test "classes and id" do
    tokens = tokenize(".small.blue#box")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :element,
        name: "div",
        attributes: %{
          "class" => [{:text, "small"}, {:text, "blue"}],
          "id" => [{:text, "box"}]
        }
      }]
    } = ast
  end

  test "raw text only" do
    tokens = tokenize("| hi")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :raw_text,
        value: "hi",
        token: {_, _, _}
      }]
    } = ast
  end

  test "double raw text" do
    tokens = tokenize("| hi\n| hello")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :raw_text,
        value: "hi",
        token: {_, _, _}
      }, %{
        type: :raw_text,
        value: "hello",
        token: {_, _, _}
      }]
    } = ast
  end

  test "buffered text only" do
    tokens = tokenize("= hi")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :buffered_text,
        value: "hi",
        token: {{1, 3}, :buffered_text, "hi"}
      }]
    } == ast
  end

  test "unescaped text only" do
    tokens = tokenize("!= hi")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :unescaped_text,
        value: "hi",
        token: {{1, 4}, :unescaped_text, "hi"}
      }]
    } == ast
  end

  test "unescaped text with element" do
    tokens = tokenize("div!= hi")
    ast = compile(tokens)
    assert ast == %{
      type: :document,
      children: [%{
        type: :element,
        name: "div",
        token: {{1, 1}, :element_name, "div"},
        children: [%{
          type: :unescaped_text,
          value: "hi",
          token: {{1, 7}, :unescaped_text, "hi"}
        }]
      }]
    }
  end

  test "statement with children" do
    tokens = tokenize("- hi\n  div")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :statement,
        value: "hi",
        children: [%{
          name: "div",
          token: {{2, 3}, :element_name, "div"},
          type: :element
        }],
      token: {{1, 3}, :statement, "hi"}
      }]
    } == ast
  end

  test "if ... end" do
    tokens = tokenize("= if @x do\n  div")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :buffered_text,
        value: "if @x do",
        open: true,
        close: "end",
        token: {{1, 3}, :buffered_text, "if @x do"},
        children: [%{
          type: :element,
          name: "div",
          token: {{2, 3}, :element_name, "div"}
        }],
      }]
    } == ast
  end

  test "if ... else ... end" do
    tokens = tokenize("= if @x do\n  div\n- else\n  span")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :buffered_text,
        value: "if @x do",
        open: true,
        token: {{1, 3}, :buffered_text, "if @x do"},
        children: [%{
          type: :element,
          name: "div",
          token: {{2, 3}, :element_name, "div"}
        }],
      }, %{
        type: :statement,
        value: "else",
        open: true,
        close: "end",
        token: {{3, 3}, :statement, "else"},
        children: [%{
          type: :element,
          name: "span",
          token: {{4, 3}, :element_name, "span"}
        }],
      }]
    } == ast
  end

  test "try ... catch ... end" do
    tokens = tokenize("= try do\n  div\n- catch ->\n  span")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :buffered_text,
        value: "try do",
        open: true,
        token: {{1, 3}, :buffered_text, "try do"},
        children: [%{
          type: :element,
          name: "div",
          token: {{2, 3}, :element_name, "div"}
        }],
      }, %{
        type: :statement,
        value: "catch ->",
        open: true,
        close: "end",
        token: {{3, 3}, :statement, "catch ->"},
        children: [%{
          type: :element,
          name: "span",
          token: {{4, 3}, :element_name, "span"}
        }],
      }]
    } == ast
  end

  test "try ... end" do
    tokens = tokenize("= try do\n  div")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :buffered_text,
        value: "try do",
        open: true,
        close: "end",
        token: {{1, 3}, :buffered_text, "try do"},
        children: [%{
          type: :element,
          name: "div",
          token: {{2, 3}, :element_name, "div"}
        }],
      }]
    } == ast
  end

  test "cond do" do
    tokens = tokenize("= cond do\n  div")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :buffered_text,
        value: "cond do",
        open: true,
        close: "end",
        token: {{1, 3}, :buffered_text, "cond do"},
        children: [%{
          type: :element,
          name: "div",
          token: {{2, 3}, :element_name, "div"}
        }],
      }]
    } == ast
  end

  test "script." do
    tokens = tokenize("script.\n  alert('hello')")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :element,
        name: "script",
        token: {{1, 1}, :element_name, "script"},
        children: [%{
          type: :block_text,
          value: "alert('hello')",
          token: {{2, 3}, :subindent, "alert('hello')"}
        }],
      }]
    } == ast
  end

  test "comment in the middle" do
    tokens = tokenize("div\n//- hi\nh1")
    ast = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :element,
        name: "div",
        token: {{1, 1}, :element_name, "div"}
      }, %{
        type: :element,
        name: "h1",
        token: {{3, 1}, :element_name, "h1"}
      }]
    } == ast
  end

end
