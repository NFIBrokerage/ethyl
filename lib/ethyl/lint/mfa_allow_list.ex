defmodule Ethyl.Lint.MfaAllowlist do
  @moduledoc """
  A linter that blocks access to functions that read from system state
  """

  alias Ethyl.Lint
  require Ethyl.AstTransforms, as: AstTransforms

  # configuration, datetime, etc.

  @behaviour Lint

  @allowlist [
               Atom,
               Base,
               Bitwise,
               {Date, except: [utc_today: :*]},
               {DateTime, except: [utc_now: :*, now: :*, now!: :*]},
               {Enum, except: [random: :*]},
               Float,
               Function,
               Integer,
               {Kernel,
                except: [
                  alias!: :*,
                  binding: :*,
                  exit: :*,
                  apply: 3,
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
    |> Lint.traverse(&traverse(&1, &2, source))
    |> Enum.reverse()
  end

  defp traverse(ast, lints, source)

  defp traverse(AstTransforms.mfa(m, f, as, meta), lints, source)
       when AstTransforms.is_mfa(m, f, as) do
    arity = length(as)

    if allowed?(m, f, arity) do
      lints
    else
      [new_lint(m, f, arity, meta, source) | lints]
    end
  end

  defp traverse(_ast, lints, _source) do
    lints
  end

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
