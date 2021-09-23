defmodule Ethyl do
  @moduledoc """
  A non-general, purely functional subset of Elixir
  """

  alias Ethyl.Context

  @doc """
  Compiles an ethyl reduction

  This can be used to write ethyl code inline in Elixir code
  """
  defmacro ethyl(do: body) do
    Ethyl.from_elixir_ast(
      body,
      Context.from_elixir_env(__CALLER__)
    )
  end

  @doc """
  Transpiles an Elixir AST into an Ethyl AST
  """
  @spec from_elixir_ast(ast :: tuple(), context :: Context.t()) ::
          ast :: tuple()
  def from_elixir_ast(ast, context) do
    {new_ast, _context} = Macro.postwalk(ast, context, &transpile/2)

    new_ast
  end

  # We transpile defmodule/2 to do two things.
  # Usually defmodule/2 is an imperative language feature which you use to
  # say "hey go compile me this quote block as this name (atom)". In ethyl,
  # defmodule/2 defines a value (atom) which you may bind, and that binding
  # can be used as the reference to the module. You cannot use the module name
  # as written.
  defp transpile(
         {:defmodule, defmodule_meta,
          [{:__aliases__, alias_meta, alias}, body]},
         context
       ) do
    modulename = {:__aliases__, alias_meta, [context.id | alias]}
    moduledef = {:defmodule, defmodule_meta, [modulename, body]}

    ast =
      quote do
        unquote(moduledef)
        unquote(modulename)
      end

    {ast, context}
  end

  defp transpile({:import, _meta, [path]}, context) when is_binary(path) do
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

  defp transpile(ast, context) do
    # IO.inspect(ast)
    {ast, context}
  end

  @doc """
  Evaluates an ethyl expression in the given path with the given context

  This function is used under the hood by `from_elixir_ast/2` when using
  `import`.

  Note that this function calls out to `Code.eval_quoted/3` which is
  potentially dangerous: only use this function if you know ahead of
  time that the contents of `path` are safe to evaluate.
  """
  @spec eval_file!(String.t(), Context.t(), Code.binding(), Keyword.t()) ::
          {term(), Code.binding()}
  def eval_file!(path, context, bindings \\ [], opts \\ []) do
    opts = Keyword.merge([file: path], opts)

    path
    |> File.read!()
    |> Code.string_to_quoted!()
    |> from_elixir_ast(context)
    |> Code.eval_quoted(bindings, opts)
  end
end
