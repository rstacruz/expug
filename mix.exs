defmodule Expug.Mixfile do
  use Mix.Project

  @version "0.9.0"
  @description """
  Indented shorthand templates for HTML. (pre-release)
  """

  def project do
    [app: :expug,
     version: @version,
     description: @description,
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/rstacruz/expug",
     homepage_url: "https://github.com/rstacruz/expug",
     docs: docs(),
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:earmark, "~> 1.2.3", only: :dev},
      {:ex_doc, "~> 0.18.1", only: :dev}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def package do
    [
      maintainers: ["Rico Sta. Cruz"],
      licenses: ["MIT"],
      files: ["lib", "mix.exs", "README.md"],
      links: %{github: "https://github.com/rstacruz/expug"}
    ]
  end

  def docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras:
        Path.wildcard("*.md") ++
        Path.wildcard("docs/**/*.md")
    ]
  end
end
