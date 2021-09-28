defmodule EthylTest do
  use ExUnit.Case, async: true

  import Ethyl, only: [ethyl: 1]

  test "basic arithmetic and function definitions can be written as usual" do
    expression =
      ethyl do
        fn x, y -> x + y end
      end

    assert expression.(1, 2) == 1 + 2
    assert expression.(3, 4) == 3 + 4

    assert expression.(78_564_312_875, 8_764_653_128_756_431) ==
             78_564_312_875 + 8_764_653_128_756_431
  end

  test "modules defined in ethyl inherit a global name based on their context ID" do
    # aliases are lexical :)
    call_foo = fn -> Foo.foo() end

    expression =
      ethyl do
        defmodule Foo do
          def foo, do: 42
        end
      end

    assert is_atom(expression)
    assert expression.foo() == 42
    assert_raise UndefinedFunctionError, call_foo
  end

  test "basic control-flow works as expected" do
    expression =
      ethyl do
        defmodule Foo do
          def with_case(x) do
            case x do
              42 -> :ok
              _ -> :error
            end
          end

          def with_if(x) do
            if x == 42, do: :ok, else: :error
          end

          def with_with(x) do
            with 42 <- x, do: :ok, else: (_ -> :error)
          end

          def with_cond(x) do
            cond do
              x == 42 -> :ok
              true -> :error
            end
          end
        end
      end

    assert expression.with_case(42) == :ok
    assert expression.with_case(1) == :error

    assert expression.with_if(42) == :ok
    assert expression.with_if(1) == :error

    assert expression.with_with(42) == :ok
    assert expression.with_with(1) == :error

    assert expression.with_cond(42) == :ok
    assert expression.with_cond(1) == :error
  end

  test "one may import files" do
    expression =
      ethyl do
        import "./support/foo.exs"
      end

    assert is_atom(expression)
    assert expression.foo() == 42
    assert_raise UndefinedFunctionError, fn -> Foo.foo() end
  end

  test "a module can be defined and captured" do
    {expression, []} =
      Ethyl.eval_file!(
        "test/corpus/good/evolver.exs",
        Ethyl.Context.from_elixir_env(__ENV__)
      )

    assert expression.([:a, :b, :c], %{counter: 0}) == %{counter: 3}
  end

  test "the pipe operator works as expected" do
    expression =
      ethyl do
        fn x -> x |> String.trim() end
      end

    assert expression.("hello ") == "hello"
  end
end
