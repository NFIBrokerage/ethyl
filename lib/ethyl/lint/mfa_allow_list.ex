defmodule Ethyl.Lint.MfaAllowlist do
  @moduledoc """
  A linter that blocks access to functions that perform impure side-effects
  """

  alias Ethyl.Lint
  require Ethyl.AstTransforms, as: AstTransforms

  @behaviour Lint

  @allowlist [
               Atom,
               Base,
               Bitwise,
               {Date, except: [utc_today: :*]},
               {DateTime, except: [utc_now: :*, now: :*, now!: :*]},
               {Enum, except: [random: :*]},
               Float,
               {Function, except: [capture: :*]},
               Integer,
               {Kernel,
                except: [
                  alias!: :*,
                  binding: :*,
                  exit: :*,
                  apply: :*,
                  make_ref: :*,
                  node: :*,
                  self: :*,
                  send: :*,
                  spawn: :*,
                  spawn_link: :*,
                  spawn_monitor: :*,
                  use: :*,
                  var!: :*
                ]},
               Module,
               {NaiveDateTime, except: [utc_now: :*, local_now: :*]},
               Regex,
               {String, except: [to_atom: :*]},
               {Time, except: [utc_now: :*]},
               Tuple,
               URI,
               Version,
               Version.Requirement,
               Path,
               {Ethyl, only: [eval_file!: 2]},
               {Ethyl.ModuleTree, only: [module_in: 2]}
             ]
             |> Lint.Helpers.create_allow_list()

  @impl Lint
  def lint(source) do
    source
    |> Lint.traverse(&traverse/3)
    |> Enum.reverse()
  end

  defp traverse(ast, lints, source)

  defp traverse(AstTransforms.mfa(m, f, as, meta), lints, source)
       when AstTransforms.is_mfa(m, f, as) do
    arity = length(as)

    with true <- module?(m),
         false <- allowed?(m, f, arity) do
      [new_lint(m, f, arity, meta, source) | lints]
    else
      _ -> lints
    end
  end

  defp traverse(_ast, lints, _source) do
    lints
  end

  defp module?({:__aliases__, _, _}), do: true
  defp module?(m) when is_atom(m), do: true
  defp module?(_), do: false

  defp allowed?(m, f, arity) do
    with {:ok, fa_map} <- Map.fetch(@allowlist, to_module_key(m)),
         {:ok, a_list} <- Map.fetch(fa_map, f) do
      arity in a_list
    else
      :error -> false
    end
  end

  defp new_lint(m, f, arity, meta, source) do
    %Lint{
      linter: __MODULE__,
      file: Keyword.get(meta, :file) || source.path,
      line: Keyword.get(meta, :line),
      description:
        "#{m |> to_module_key |> inspect}.#{f}/#{arity}" <>
          " is not an allowed function call"
    }
  end

  defp to_module_key({:__aliases__, _, module_path}),
    do: Module.concat(module_path)

  defp to_module_key(module) when is_atom(module), do: module
end
