defmodule Ethyl.Lint.DynamicFunctionApplication do
  @moduledoc """
  A linter that catches dynamic applications of functions

  E.g.

      binding.function_name(args)
  """

  alias Ethyl.Lint
  require Ethyl.AstTransforms, as: AstTransforms

  @behaviour Lint

  @impl Lint
  def lint(source) do
    source
    |> Lint.traverse(&traverse/3)
    |> Enum.reverse()
  end

  defp traverse(ast, lints, source)

  defp traverse(AstTransforms.mfa(module, _f, _a, meta) = ast, lints, source) do
    case module do
      {:__aliases__, _, _} ->
        lints

      module when is_atom(module) ->
        lints

      _binding ->
        [new_lint(ast, meta, source) | lints]
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
