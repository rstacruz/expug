defmodule Expug.TokenizerTools.State do
  @moduledoc """
  The state used by the tokenizer.

      %{ tokens: [], source: "...", position: 0, options: ... }

  ## Also see

  - `Expug.TokenizerTools`
  """
  defstruct [:tokens, :source, :position, :options]
end

