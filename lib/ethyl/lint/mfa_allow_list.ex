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
               {Kernel.SpecialForms, except: [receive: :*]},
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
    {_ast, state} =
      Macro.prewalk(
        source.ast,
        %{lints: [], allowlist: @allowlist},
        &traverse(&1, &2, source)
      )

    Enum.reverse(state.lints)
  end

  defp traverse(ast, state, source)

  defp traverse(
         Ast.mfa(
           Ast.module(Kernel),
           :defmodule,
           [{:__aliases__, _, module_path}, _body],
           _meta
         ) = ast,
         state,
         source
       ) do
    module =
      module_path
      |> Enum.reject(&(&1 == source.context.id))
      |> Module.concat()

    state =
      update_in(
        state.allowlist,
        &Helpers.allowlist_module(&1, to_module_key(module))
      )

    {ast, state}
  end

  # we treat captures differently because they may encase MFAs, so we could
  # end up with duplicate lints
  # we solve this by marking the encased MFA as captured and storing the arity
  # in the metadata
  defp traverse(Ast.capture(_, arity, _meta) = ast, state, _source) do
    # update the MFA's metadata
    ast =
      update_in(
        ast,
        [Access.elem(2), Access.at(0), Access.elem(2), Access.at(0)],
        fn mfa ->
          Macro.update_meta(mfa, &Keyword.put(&1, :captured_arity, arity))
        end
      )

    {ast, state}
  end

  defp traverse(Ast.mfa(m, f, as, meta) = ast, state, source)
       when Ast.is_mfa(m, f, as) do
    arity = Keyword.get(meta, :captured_arity, length(as))

    state =
      with true <- module?(m),
           false <- allowed?(m, f, arity, state.allowlist) do
        update_in(state.lints, &[new_lint(m, f, arity, meta, source) | &1])
      else
        _ -> state
      end

    {ast, state}
  end

  defp traverse(ast, state, _source) do
    {ast, state}
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
