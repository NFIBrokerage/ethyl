defmodule Mix.Tasks.Compile.Ethyl do
  use Mix.Task.Compiler

  @recursive true
  @manifest "compile.ethyl"

  @moduledoc """
  A task to compile Ethyl expressions into BEAM bytecode

  Compiling Ethyl expressions may be valuable so that one can measure code
  coverage with a test suite.

  The design of this compiler is loosly based on the [1.12 Elixir
  compiler](https://github.com/elixir-lang/elixir/blob/a64d42f5d3cb6c32752af9d3312897e8cd5bb7ec/lib/mix/lib/mix/tasks/compile.elixir.ex#L1),
  but it is adapted for Ethyl's unique structures. Namely, This compiler
  wraps expressions in superfluous modules. This is necessary to measure
  coverage with the built-in `:cover` module.
  """

  @impl Mix.Task.Compiler
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [force: :boolean])

    project = Mix.Project.config()
    dest = Mix.Project.compile_path(project)

    srcs =
      (project[:ethylc_globs] || ["lib/**/*.exs"])
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.map(&Path.expand/1)

    Ethyl.Compiler.compile(manifest(), srcs, dest, opts[:force] || false)
  end

  @impl Mix.Task.Compiler
  def manifests, do: [manifest()]
  def manifest, do: Path.join(Mix.Project.manifest_path(), @manifest)
end
