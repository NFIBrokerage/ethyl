defmodule Mix.Tasks.Compile.Ethyl do
  use Mix.Task
  @recursive true

  @doc false
  def run(_args) do
    project = Mix.Project.config()
    dest = Mix.Project.compile_path(project)
    File.mkdir_p!(dest)

    srcs =
      List.wrap(project[:ethylc_globs] || "lib/**/*.exs")
      |> Enum.flat_map(&Path.wildcard/1)

    _ = Mix.Tasks.Ethyl.Lint.run(srcs)

    srcs
    |> length()
    |> compile_message()
    |> Mix.shell().info()

    srcs
    |> Task.async_stream(&compile_file(&1, dest), timeout: 20_000)
    |> Stream.run()
  end

  defp compile_file(file, dest) do
    context = Ethyl.Context.from_filename(file)

    ast =
      file
      |> File.read!()
      |> Code.string_to_quoted!()
      |> replace_imports_with_remote_calls(Path.dirname(file), dest)
      |> Ethyl.from_elixir_ast(context)

    ast =
      quote do
        defmodule unquote(context.id) do
          def value do
            unquote(ast)
          end
        end
      end

    [{module, beam}] = Code.compile_quoted(ast, file)

    file =
      [dest, Atom.to_string(module) <> ".beam"]
      |> Path.join()
      |> File.open!([:write])

    IO.binwrite(file, beam)
  end

  defp compile_message(1), do: "Compiling 1 file (.exs)"
  defp compile_message(n), do: "Compiling #{n} files (.exs)"

  # Replace all calls to import/1 (with binaries) with a call to the
  # compiled module's value/0 callback
  defp replace_imports_with_remote_calls(ast, path, dest) do
    Macro.postwalk(ast, fn
      {:import, _meta, [import_path]} ->
        file =
          path
          |> Path.join(import_path)
          |> Path.expand()

        compile_file(file, dest)

        module = Ethyl.Context.id_for_filename(file)
    
        quote do
          unquote(Macro.escape(module)).value()
        end

      ast ->
        ast
    end)
  end
end
