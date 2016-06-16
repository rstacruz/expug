defmodule ExpugCompilerTest do
  use ExUnit.Case

  import Expug.Tokenizer, only: [tokenize: 1]
  import Expug.Compiler, only: [compile: 1]

  doctest Expug.Compiler

  test "doctype only" do
    {:ok, tokens} = tokenize("doctype html5")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize("div")
    {:ok, ast} = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        name: "div",
        type: :element
      }]
    } = ast
  end

  test "doctype and tag" do
    {:ok, tokens} = tokenize("doctype html5\ndiv")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize("doctype html5\ndiv#box")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize("div.blue.small")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize("div= hello")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize("doctype html5\ndiv\nspan")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize("head\n  title")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize("head\n  title\n    span")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize("head\n  title\n    span\n  meta")
    {:ok, ast} = compile(tokens)
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
  #   {:ok, tokens} = tokenize("head\n  title\n    span\n meta")
  #   {:error, params} = compile(tokens)
  #   assert params == %{
  #     type: :ambiguous_indentation,
  #     position: {4, 2}
  #   }
  # end

  test "attributes" do
    {:ok, tokens} = tokenize("div(style='color: blue')")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize("div(id='box' style='color: blue')")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize("div(src=1 src=2)")
    {:ok, ast} = compile(tokens)
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

  test "start with class" do
    {:ok, tokens} = tokenize(".hello")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize("#hello")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize(".small.blue#box")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize("| hi")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize("| hi\n| hello")
    {:ok, ast} = compile(tokens)
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
    {:ok, tokens} = tokenize("= hi")
    {:ok, ast} = compile(tokens)
    assert %{
      type: :document,
      children: [%{
        type: :buffered_text,
        value: "hi",
        token: {_, _, _}
      }]
    } = ast
  end
end
