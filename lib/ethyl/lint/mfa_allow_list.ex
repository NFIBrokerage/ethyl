defmodule Ethyl.Lint.MfaAllowlist do
  @moduledoc """
  A linter that blocks access to functions that perform impure side-effects
  """

  alias Ethyl.{Lint, Lint.Helpers}
  require Ethyl.AstTransforms, as: Ast

  @behaviour Lint

  @allowlist [
               Access,
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
               Map,
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
             |> Helpers.create_allow_list()

  @impl Lint
  def lint(source) do
    source
    |> Lint.traverse(&traverse/3, %{lints: [], allowlist: @allowlist})
    |> Map.fetch!(:lints)
    |> Enum.reverse()
  end

  defp traverse(ast, state, source)

  defp traverse(
         Ast.mfa(
           Ast.module(Kernel),
           :defmodule,
           [{:__aliases__, _, module_path}, _body],
           _meta
         ),
         state,
         source
       ) do
    module =
      module_path
      |> Enum.reject(&(&1 == source.context.id))
      |> Module.concat()

    update_in(
      state.allowlist,
      &Helpers.allowlist_module(&1, to_module_key(module))
    )
  end

  defp traverse(Ast.mfa(m, f, as, meta), state, source)
       when Ast.is_mfa(m, f, as) do
    arity = length(as)

    with true <- module?(m),
         false <- allowed?(m, f, arity, state.allowlist) do
      update_in(state.lints, &[new_lint(m, f, arity, meta, source) | &1])
    else
      _ -> state
    end
  end

  defp traverse(_ast, state, _source) do
    state
  end

  defp module?({:__aliases__, _, _}), do: true
  defp module?(m) when is_atom(m), do: true
  defp module?(_), do: false

  defp allowed?(m, f, arity, allowlist) do
    with {:ok, fa_map} when is_map(fa_map) <-
           Map.fetch(allowlist, to_module_key(m)),
         {:ok, a_list} <- Map.fetch(fa_map, f) do
      arity in a_list
    else
      {:ok, :*} -> true
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
