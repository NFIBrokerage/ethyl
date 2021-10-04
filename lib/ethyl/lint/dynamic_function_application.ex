defmodule Ethyl.Lint.DynamicFunctionApplication do
  @moduledoc """
  A linter that catches dynamic applications of functions

  E.g.

      binding.function_name(args)
  """

  alias Ethyl.Lint
  require Ethyl.AstTransforms, as: Ast

  defguardp is_elixir_module(module)
            when is_tuple(module) and tuple_size(module) == 3 and
                   elem(module, 0) == :__aliases__

  defguardp is_erlang_module(module) when is_atom(module)

  @behaviour Lint

  @impl Lint
  def lint(source) do
    source
    |> Lint.traverse(&traverse/3)
    |> Enum.reverse()
  end

  defp traverse(ast, lints, source)

  # this catches function captures of bindings by ignoring the `no_parens: true`
  # in the meta for that application
  defp traverse(
         Ast.capture(Ast.mfa(module, _f, _a, meta), _arity, _meta) = ast,
         lints,
         source
       )
       when not (is_erlang_module(module) or is_elixir_module(module)) do
    [new_lint(ast, meta, source) | lints]
  end

  defp traverse(Ast.mfa(module, _f, _a, meta) = ast, lints, source)
       when not (is_erlang_module(module) or is_elixir_module(module)) do
    if Keyword.get(meta, :no_parens, false) == false do
      [new_lint(ast, meta, source) | lints]
    else
      lints
    end
  end

  defp traverse(_ast, lints, _source) do
    lints
  end

  defp new_lint(ast, meta, source) do
    %Lint{
      linter: __MODULE__,
      file: Keyword.get(meta, :file) || source.path,
      line: Keyword.get(meta, :line),
      description:
        "calling functions on dynamic modules is not allowed: #{Macro.to_string(ast)}"
    }
  end
end
