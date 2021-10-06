defmodule Ethyl.MixProject do
  use Mix.Project

  @source_url "https://github.com/NFIBrokerage/ethyl"
  @version_file Path.join(__DIR__, ".version")
  @external_resource @version_file
  @version (case Regex.run(~r/^v([\d\.\w-]+)/, File.read!(@version_file),
                   capture: :all_but_first
                 ) do
              [version] -> version
              nil -> "0.0.0"
            end)

  def project do
    [
      app: :ethyl,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: Chaps],
      preferred_cli_env: [
        chaps: :test,
        "chaps.html": :test,
        "chaps.github": :test,
        docs: :dev,
        bless: :test,
        credo: :test
      ],
      package: package(),
      description: description(),
      source_url: @source_url,
      name: "Ethyl",
      docs: docs()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    []
  end

  defp deps do
    [
      {:ex_doc, "~> 0.24", only: [:dev], runtime: false},
      {:credo, "~> 1.0", only: [:test], runtime: false},
      {:chaps, "~> 0.16", only: [:test]},
      {:bless, "~> 1.2", only: [:test]}
    ]
  end

  defp package do
    [
      name: "ethyl",
      files: ~w(lib .formatter.exs mix.exs README.md .version LICENSE),
      licenses: [],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => @source_url <> "/blobs/main/CHANGELOG.md"
      }
    ]
  end

  defp description do
    "A pure, non-general subset of Elixir"
  end

  defp docs do
    [
      deps: [],
      extras: [
        "CHANGELOG.md"
      ],
      groups_for_extras: [
        Guides: Path.wildcard("guides/*.md")
      ]
    ]
  end
end
