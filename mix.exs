defmodule Exslim.Mixfile do
  use Mix.Project

  def project do
    [app: :exslim,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/rstacruz/exslim",
     package: package,
     deps: deps]
  end

  def application do
    [applications: []]
  end

  defp deps do
    []
  end

  def package do
    [
      maintainers: ["Rico Sta. Cruz"],
      licenses: ["MIT"],
      files: ["lib", "mix.exs", "README.md"],
      links: %{github: "https://github.com/rstacruz/exslim"}
    ]
  end
end
