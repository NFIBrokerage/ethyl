defmodule Ethyl.MixProject do
  use Mix.Project

  def project do
    [
      app: :ethyl,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.github": :test,
        docs: :dev,
        bless: :test,
        credo: :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.24", only: [:dev], runtime: false},
      {:credo, "~> 1.0", only: [:test], runtime: false},
      {:excoveralls, "~> 0.14", only: [:test]},
      {:bless, "~> 1.0", only: [:test]}
    ]
  end
end
