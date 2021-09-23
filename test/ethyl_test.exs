defmodule EthylTest do
  use ExUnit.Case
  doctest Ethyl

  test "greets the world" do
    assert Ethyl.hello() == :world
  end
end
