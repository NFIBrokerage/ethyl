defmodule Ethyl.LintTest do
  use ExUnit.Case, async: true

  defmacrop assert_expanded(lhs, do: rhs) do
    quote do
      lhs =
        unquote(lhs)
        |> Ethyl.Lint.expand_aliases()
        |> strip_meta()

      rhs = strip_meta(unquote(Macro.escape(rhs)))

      assert lhs == rhs
    end
  end

  describe "expand_aliases/1 correctly expands" do
    test "given a simple fixture using alias/1" do
      fixture =
        quote do
          alias File.Stream
          Stream.foo()
        end

      assert_expanded fixture do
        :ok
        File.Stream.foo()
      end
    end

    test "given a simple fixture using alias/2" do
      fixture =
        quote do
          alias Application, as: App
          App.foo()
        end

      assert_expanded fixture do
        :ok
        Application.foo()
      end
    end

    test "given a fixture that aliases multiple times" do
      fixture =
        quote do
          alias Foo, as: F
          alias F, as: B
          B.foo()
        end

      assert_expanded fixture do
        :ok
        :ok
        Foo.foo()
      end
    end

    test "given a fixture that does nested aliasing" do
      fixture =
        quote do
          alias Foo, as: F
          alias F.Bar, as: B
          B.foo()
        end

      assert_expanded fixture do
        :ok
        :ok
        Foo.Bar.foo()
      end
    end

    test "given a fixture aliases multiple things to the same name" do
      fixture =
        quote do
          alias Foo.Bar
          alias Baz.Bar
          Bar.foo()
        end

      assert_expanded fixture do
        :ok
        :ok
        Baz.Bar.foo()
      end
    end
  end

  defp strip_meta(ast)
  defp strip_meta({a, _meta, b}), do: {strip_meta(a), [], strip_meta(b)}
  defp strip_meta(nodes) when is_list(nodes), do: Enum.map(nodes, &strip_meta/1)
  defp strip_meta(ast), do: ast
end
