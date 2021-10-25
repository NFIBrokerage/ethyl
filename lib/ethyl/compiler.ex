defmodule Ethyl.Compiler do
  @moduledoc false

  @manifest_version 1

  # functions to compile ethyl expressions into BEAM bytecode

  def compile(manifest_path, srcs, dest, force?) do
    if force?, do: reset(manifest_path, dest)

    manifest = parse_manifest(manifest_path)

    File.mkdir_p!(dest)

    srcs
    |> Enum.reduce(manifest, &compile_file(&1, &2, dest))
    |> write_manifest(manifest_path, manifest)
  end

  defp compile_file(file, manifest, dest) do
    %Ethyl.Context{id: module} = context = Ethyl.Context.from_filename(file)

    {ast, manifest} =
      file
      |> File.read!()
      |> Code.string_to_quoted!()
      |> replace_imports_with_remote_calls(Path.dirname(file), dest, manifest)

    ast = Ethyl.from_elixir_ast(ast, context)
    hash = :erlang.md5(file)

    unless Map.get(manifest, file) == hash do
      :code.purge(module)
      :code.delete(module)

      ast =
        quote do
          defmodule unquote(module) do
            def value do
              unquote(ast)
            end
          end
        end

      [{^module, beam}] = Code.compile_quoted(ast, file)

      File.write!(beam_path(module, dest), beam)
    end

    Map.put(manifest, file, hash)
  end

  # Replace all calls to import/1 (with binaries) with a call to the
  # compiled module's value/0 callback
  defp replace_imports_with_remote_calls(ast, path, dest, manifest) do
    Macro.postwalk(ast, manifest, fn
      {:import, _meta, [import_path]}, manifest ->
        file =
          path
          |> Path.join(import_path)
          |> Path.expand()

        module = Ethyl.Context.id_for_filename(file)

        ast =
          quote do
            unquote(Macro.escape(module)).value()
          end

        {ast, Map.merge(manifest, compile_file(file, manifest, dest))}

      ast, manifest ->
        {ast, manifest}
    end)
  end

  defp parse_manifest(path) do
    {@manifest_version, %{} = manifest} =
      path |> File.read!() |> :erlang.binary_to_term()

    manifest
  rescue
    _ -> %{}
  end

  defp write_manifest(manifest, path, old_manifest) do
    newly_compiled =
      Enum.reject(manifest, fn {file, hash} ->
        Map.get(old_manifest, file) == hash
      end)

    case Enum.count(newly_compiled) do
      0 ->
        :ok

      n ->
        suffix = if n == 1, do: "", else: "s"
        Mix.shell().info("Compiled #{n} file#{suffix} (.exs)")
    end

    File.mkdir_p!(Path.dirname(path))
    data = :erlang.term_to_binary({@manifest_version, manifest}, [:compressed])
    File.write!(path, data)
  end

  defp beam_path(module, dest_path) do
    Path.join(dest_path, Atom.to_string(module) <> ".beam")
  end

  def reset(manifest_path, dest_path) do
    manifest = parse_manifest(manifest_path)

    manifest_path
    |> parse_manifest
    |> Enum.each(fn {file, _hash} ->
      module = Ethyl.Context.id_for_filename(file)
      File.rm(beam_path(module, dest_path))
      :code.purge(module)
      :code.delete(module)
    end)

    write_manifest(%{}, manifest_path, manifest)
  end
end
