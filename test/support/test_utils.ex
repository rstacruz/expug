defmodule TestUtils do
  @moduledoc """
  Helpers for tests
  """

  @doc """
  Sorts keys in a keyword list, recursively. Great for comparing keyword lists
  in tests.

      assert sort(left) == sort(right)
  """
  def sort(list) when is_list(list) do
    if is_keyword_list(list) do
      list = Enum.reduce list, list, fn {key, val}, acc ->
        Keyword.put(acc, key, sort(val))
      end
      Enum.sort_by(list, fn {key, _val} -> key end)
    else
      list
    end
  end

  def sort(default) do
    default
  end

  @doc """
  Checks if the given object is a keyword list.

      iex> TestUtils.is_keyword_list([a: 2])
      true

      iex> TestUtils.is_keyword_list([:a, :b])
      false
  """
  def is_keyword_list([{key, _val} | _]) when is_atom(key) do
    true
  end

  def is_keyword_list(_) do
    false
  end

  def detokenize(list) do
    drop_keys(list, [:token])
  end

  @doc """
  Drops certain keys from keyword lists, recursively.
  """
  def drop_keys(list, keys) when is_list(list) do
    list = Keyword.drop(list, keys)
    Enum.reduce list, list, fn {key, val}, acc ->
      Keyword.put(acc, key, drop_keys(val, keys))
    end
  end

  def drop_keys(default) do
    default
  end
end
