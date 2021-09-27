defmodule Ethyl do
  @moduledoc """
  A non-general, purely functional subset of Elixir
  """

  alias Ethyl.{AstTransforms, Context}

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
    ast
    |> AstTransforms.expand_aliases()
    |> AstTransforms.alter_compile_directives(context)
    |> AstTransforms.expand_imports()
    |> AstTransforms.expand_apply_3()
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
