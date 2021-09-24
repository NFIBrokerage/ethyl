defmodule Ethyl.Lint do
  @moduledoc """
  Functions for linting Ethyl code
  """

  @doc false
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
end
