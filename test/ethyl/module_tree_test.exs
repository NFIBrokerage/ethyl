defmodule Ethyl.ModuleTreeTest do
  use ExUnit.Case, async: true

  alias Ethyl.ModuleTree

  setup_all :fixture

  test "a fixture module tree can be constructed and accessed with module_in/2",
       c do
    assert ModuleTree.module_in(c.fixture, ~w"MyModuleTree Foo"a).foo() == :foo

    assert ModuleTree.module_in(c.fixture, ~w"MyModuleTree Foo Bar"a).bar() ==
             :bar

    assert ModuleTree.module_in(c.fixture, ~w"MyModuleTree Foo Bar Baz"a).baz() ==
             :baz
  end

  defp fixture(_c) do
    fixture =
      :code.all_loaded()
      |> Enum.filter(fn {module, _filename} ->
        module |> Atom.to_string() |> String.starts_with?("Elixir.MyModuleTree")
      end)
      |> Enum.map(fn {module, _filename} ->
        {module, module |> Module.split() |> Enum.map(&String.to_atom/1)}
      end)
      |> ModuleTree._from_module_set()

    [fixture: fixture]
  end
end
