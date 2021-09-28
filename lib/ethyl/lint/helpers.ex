# these are all helpers at compile time, no coverage for me :(
# coveralls-ignore-start
defmodule Ethyl.Lint.Helpers do
  @moduledoc false
  # helper functions/macros for writing linters

  alias Ethyl.AstTransforms

  def create_allow_list(module_list) do
    module_list
    |> Enum.flat_map(&expand_allow_entry/1)
    |> Enum.reduce(%{}, fn {module, function, arity}, acc ->
      Map.update(acc, module, %{function => [arity]}, fn fa_map ->
        Map.update(fa_map, function, [arity], &[arity | &1])
      end)
    end)
  end

  defp expand_allow_entry(module) when is_atom(module) do
    module
    |> AstTransforms.exports()
    |> Enum.map(fn {function, arity} ->
      {module, function, arity}
    end)
  end

  defp expand_allow_entry({module, only: only_functions}) do
    module
    |> expand_allow_entry()
    |> Enum.filter(fn {_m, f, a} ->
      Enum.any?(only_functions, &functions_match?(&1, {f, a}))
    end)
  end

  defp expand_allow_entry({module, except: except_functions}) do
    module
    |> expand_allow_entry()
    |> Enum.reject(fn {_m, f, a} ->
      Enum.any?(except_functions, &functions_match?(&1, {f, a}))
    end)
  end

  defp functions_match?(fa, fa), do: true
  defp functions_match?({f, :*}, {f, _}), do: true
  defp functions_match?(_, _), do: false

  def allowlist_module(allowlist, module) do
    Map.put(allowlist, module, :*)
  end
end

# coveralls-ignore-stop
