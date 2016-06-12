defmodule Expug.Mixfile do
  use Mix.Project

  def project do
    [app: :expug,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/rstacruz/expug",
     package: package,
     deps: deps]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [
      {:calliope, "~> 0.4.0", only: :test}
    ]
  end

  def package do
    [
      maintainers: ["Rico Sta. Cruz"],
      licenses: ["MIT"],
      files: ["lib", "mix.exs", "README.md"],
      links: %{github: "https://github.com/rstacruz/expug"}
    ]
  end
end
