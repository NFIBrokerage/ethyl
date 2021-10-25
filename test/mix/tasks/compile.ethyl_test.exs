defmodule Mix.Tasks.Compile.EthylTest do
  use ExUnit.Case

  setup_all do
    shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(shell) end)
  end

  test "the compile task can be invoked to compile files into BEAM bytecode" do
    assert Mix.Tasks.Compile.Ethyl.run(["--force"]) == :ok
    assert_receive {:mix_shell, :info, ["Compiled 2 files (.exs)"]}

    module =
      ~w[test corpus compile default.exs]
      |> Path.join()
      |> Path.expand()
      |> Ethyl.Context.id_for_filename()

    assert module.value() == 3

    # compiling again with --force recompiles all
    assert Mix.Tasks.Compile.Ethyl.run(["--force"]) == :ok
    assert_receive {:mix_shell, :info, ["Compiled 2 files (.exs)"]}
  end

  describe "given a corrupted manifest has been written" do
    setup do
      path = Path.join(Mix.Project.manifest_path(), "compile.ethyl")
      File.write!(path, <<0>>)
    end

    test "the compile task resets state" do
      assert Mix.Tasks.Compile.Ethyl.run(["--force"]) == :ok
      assert_receive {:mix_shell, :info, ["Compiled 2 files (.exs)"]}
    end
  end
end
