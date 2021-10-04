# chaps-ignore-start
defmodule Mix.Tasks.Ethyl.Lint do
  use Mix.Task

  @moduledoc """
  A mix task for running the Ethyl linters against specified files

  The linter may be run against a single file like so

      mix ethyl.lint path/to/ethyl/expression.exs

  Or you may pass a glob which is expanded by your shell

      mix ethyl.lint path/to/ethyl/*.exs
  """

  @shortdoc "Runs the ethyl linting suite against files"
  def run(paths) do
    paths
    |> Task.async_stream(fn path ->
      path
      |> Ethyl.Source.new()
      |> Ethyl.Lint.lint()
    end)
    |> Enum.flat_map(fn {:ok, result} -> result end)
    |> IO.inspect(label: "lints")
  end
end

# chaps-ignore-stop
