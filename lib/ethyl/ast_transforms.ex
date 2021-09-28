defmodule Ethyl.AstTransforms do
  @moduledoc false
  # functions that transform the AST

  @operator_functions ~w[. / & |>]a
  @expandable_tags ~w[|>]a

  defmacro mfa(m, f, as, meta) do
    quote do
      {{:., _, [unquote(m), unquote(f)]}, unquote(meta), unquote(as)}
    end
  end

  defmacro module({:__aliases__, _meta, module_path}) do
    quote do
      {:__aliases__, _, unquote(module_path)}
    end
  end

  # coveralls-ignore-start
  defguard is_mfa(m, f, a)
           when (is_atom(m) or is_tuple(m)) and is_atom(f) and is_list(a)

  # coveralls-ignore-stop

  @doc """
  Alter defmodule/2 and import/1 behavior to work more straightforward
  for an expression based language
  """
  def alter_compile_directives(ast, context) do
    {new_ast, _context} =
      Macro.postwalk(ast, context, &alter_compiler_directives/2)

    new_ast
  end

  # We alter defmodule/2 to do two things.
  # Usually defmodule/2 is an imperative language feature which you use to
  # say "hey go compile me this quote block as this name (atom)". In ethyl,
  # defmodule/2 defines a value (atom) which you may bind, and that binding
  # can be used as the reference to the module. You cannot use the module name
  # as written.
  defp alter_compiler_directives(
         {:defmodule, defmodule_meta,
          [{:__aliases__, alias_meta, alias} = original_modulename, body]},
         context
       ) do
    modulename = {:__aliases__, alias_meta, [context.id | alias]}
    moduledef = {:defmodule, defmodule_meta, [modulename, body]}

    ast =
      quote do
        unquote(moduledef)
        alias unquote(modulename), as: unquote(original_modulename)
        unquote(modulename)
      end

    {ast, context}
  end

  # we also alter import/1 to allow binaries to be passed as local
  # paths, so one may import values from other ethyl files
  defp alter_compiler_directives({:import, _meta, [path]}, context)
       when is_binary(path) do
    ast =
      quote do
        {value, _bindings} =
          Ethyl.eval_file!(
            Path.join(__DIR__, unquote(path)),
            unquote(Macro.escape(context))
          )

        value
      end

    {ast, context}
  end

  defp alter_compiler_directives(ast, context) do
    {ast, context}
  end

  # strip the AST of all aliases
  # this must be performed as a pre-processing step in order to properly
  # identify which modules/functions/arities are being called
  def expand_aliases(ast) do
    {ast, _aliases} = Macro.postwalk(ast, [], &do_expand_aliases/2)
    ast
  end

  defp do_expand_aliases(ast, aliases)

  # alias/2
  defp do_expand_aliases({:alias, _, [module, [as: alias]]}, aliases) do
    {:ok, [{strip_alias_tag(alias), strip_alias_tag(module)} | aliases]}
  end

  # alias/1
  defp do_expand_aliases({:alias, _, [{:__aliases__, _, module_path}]}, aliases) do
    {:ok, [{Enum.take(module_path, -1), module_path} | aliases]}
  end

  defp do_expand_aliases({:__aliases__, meta, path}, aliases) do
    {{:__aliases__, meta, expand_alias(path, aliases)}, aliases}
  end

  defp do_expand_aliases(ast, aliases), do: {ast, aliases}

  defp expand_alias(module_path, aliases) do
    Enum.reduce(aliases, module_path, fn {alias, expanded}, module_path ->
      case sublist_rest(alias, module_path) do
        {:ok, rest} -> expanded ++ rest
        :error -> module_path
      end
    end)
  end

  # is as an ordered subset of bs? if so, return {:ok, rest_bs} else :error
  defp sublist_rest(as, bs)
  defp sublist_rest([e | as], [e | bs]), do: sublist_rest(as, bs)
  defp sublist_rest([], bs), do: {:ok, bs}
  defp sublist_rest(_as, _bs), do: :error

  defp strip_alias_tag({:__aliases__, _meta, module_path}), do: module_path

  @doc """
  Expands import/1 and import/2 statements

  Replaces the import with a require/1 and replaces any instances it can find
  with a fully qualified module call.

  YARD imports are lexical, not global.
  """
  def expand_imports(ast) do
    imports =
      Kernel
      |> exports()
      |> Map.new(fn {func, arity} ->
        {{func, arity}, quote(do: Kernel)}
      end)

    {ast, _imports} = Macro.postwalk(ast, imports, &do_expand_imports/2)
    ast
  end

  defp do_expand_imports(ast, imports)

  # turn an import/1 or import/2 into a require/1 and add it to the `imports`
  # map
  defp do_expand_imports({:import, _, [import | config]}, imports)
       when is_atom(import) or is_tuple(import) do
    export_transform =
      case config do
        [[only: only_exports]] ->
          fn exports -> Enum.filter(exports, &(&1 in only_exports)) end

        [[except: except_exports]] ->
          fn exports -> Enum.reject(exports, &(&1 in except_exports)) end

        _ ->
          fn exports -> exports end
      end

    imports =
      import
      |> exports()
      |> export_transform.()
      |> Enum.reduce(imports, fn {func, arity}, acc ->
        Map.put(acc, {func, arity}, import)
      end)

    ast =
      quote do
        require unquote(import)
      end

    {ast, imports}
  end

  # catches the very specific case of an imported function in a function
  # capture
  defp do_expand_imports(
         {:&, _, [{:/, _, [{function, _, _scope}, arity]}]} = ast,
         imports
       )
       when is_integer(arity) do
    ast =
      case Map.fetch(imports, {function, arity}) do
        {:ok, module} ->
          quote(do: &(unquote(module).unquote(function) / unquote(arity)))

        :error ->
          ast
      end

    {ast, imports}
  end

  # attempt to expand a function call
  defp do_expand_imports({func, _, args} = ast, imports)
       when is_atom(func) and is_list(args) and func not in @operator_functions do
    ast =
      case Map.fetch(imports, {func, length(args)}) do
        {:ok, module} ->
          {{:., [], [module, func]}, [], args}

        :error ->
          ast
      end

    {ast, imports}
  end

  defp do_expand_imports(ast, imports), do: {ast, imports}

  @doc """
  Gives the exported functions and macros in a keyword list

  Accepts quoted Elixir modules or Erlang modules. Returns exported functions
  and macros as a keyword list where the key is the function or macro name and
  the value is the arity.
  """
  @spec exports(Macro.t() | atom()) :: Keyword.t()
  def exports({:__aliases__, _, module_path}) when is_list(module_path) do
    module_path |> Module.concat() |> exports()
  end

  def exports(module) when is_atom(module) do
    Code.ensure_loaded(module)

    cond do
      function_exported?(module, :__info__, 1) ->
        module.__info__(:functions) ++ module.__info__(:macros)

      function_exported?(module, :module_info, 1) ->
        module.module_info(:exports)

      # coveralls-ignore-start
      true ->
        []
        # coveralls-ignore-stop
    end
  end

  @doc """
  Strips the metadata from a tag

  This can be useful for performing equality tests on ASTs created by different
  means.
  """
  @spec strip_meta(Macro.t()) :: Macro.t()
  def strip_meta(ast)
  def strip_meta({a, _meta, b}), do: {strip_meta(a), [], strip_meta(b)}
  def strip_meta(nodes) when is_list(nodes), do: Enum.map(nodes, &strip_meta/1)
  def strip_meta(ast), do: ast

  @doc """
  Expands all calls to apply/3

  Calls to apply/3 are applied as a preprocessor step. Dynamic apply/3 is
  disallowed.

  Dynamic apply/2 is allowed.
  """
  @spec expand_apply_3(Macro.t()) :: Macro.t()
  def expand_apply_3(ast) do
    Macro.prewalk(ast, &do_expand_apply_3/1)
  end

  defp do_expand_apply_3(ast)

  defp do_expand_apply_3(
         mfa(module(Kernel), :apply, [module, function, args], _) = ast
       ) do
    expanded_call =
      quote do
        unquote(module).unquote(function)(unquote_splicing(args))
      end

    case module do
      module when is_atom(module) ->
        expanded_call

      {:__aliases__, _, _} ->
        expanded_call

      _ ->
        ast
    end
  end

  defp do_expand_apply_3(ast), do: ast

  def recursive_expand(ast) do
    Macro.prewalk(ast, &do_recursive_expand(&1, __ENV__))
  end

  defp do_recursive_expand({tag, _, _} = ast, env)
       when tag in @expandable_tags do
    Macro.expand(ast, env)
  end

  defp do_recursive_expand(ast, _env), do: ast
end
