defmodule Ethyl.MixProject do
  use Mix.Project

  def project do
    [
      app: :ethyl,
      version: "0.1.0",
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
      bless_suite: [
        compile: ["--warnings-as-errors", "--force"],
        "chaps.html": [],
        format: ["--check-formatted"],
        credo: [],
        "deps.unlock": ["--check-unused"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ex_doc, "~> 0.24", only: [:dev], runtime: false},
      {:credo, "~> 1.0", only: [:test], runtime: false},
      {:chaps, "~> 0.16", only: [:test]},
      {:bless, "~> 1.0", only: [:test]}
    ]
  end
end
