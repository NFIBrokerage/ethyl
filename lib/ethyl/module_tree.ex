defmodule Ethyl.ModuleTree do
  @moduledoc """
  An admittedly odd data structure for either invoking functions or accessing
  submodules

  This data structure allows one to describe a module hierarchy as a tree of
  structs without losing any modules.
  """

  @derive {Inspect, only: [:module]}

  defstruct [:module, children: %{}]

  def _from_module_set(modules) do
    _map_tree = Enum.reduce(modules, %__MODULE__{}, &put_in_recursive/2)
  end

  defp put_in_recursive({module, []}, node) do
    %__MODULE__{node | module: module}
  end

  defp put_in_recursive({module, [key | keys]}, node) do
    put_in(
      node.children[key],
      put_in_recursive({module, keys}, node.children[key] || %__MODULE__{})
    )
  end

  @doc """
  Gets a module within the tree
  """
  def module_in(tree, path)

  def module_in(%__MODULE__{module: module}, []), do: module

  def module_in(tree, [key | keys]) when is_atom(key) do
    module_in(tree.children[key], keys)
  end
end
