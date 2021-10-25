defmodule Ethyl.Context do
  @moduledoc """
  A data structure describing the context in which an ethyl expression is
  defined.
  """

  @typedoc """
  TODO
  """
  @type t :: %__MODULE__{id: atom()}

  defstruct [:id]

  def from_elixir_env(%Macro.Env{} = env) do
    id =
      ["Ethyl", env.file, env.line]
      |> Enum.map(&to_string/1)
      |> Enum.map(&String.replace(&1, ".", "::"))
      |> Enum.join("::")
      |> String.to_atom()

    %__MODULE__{id: id}
  end

  # these are used internally by the compiler
  @doc false
  def from_filename(file) do
    %__MODULE__{id: id_for_filename(file)}
  end

  @doc false
  def id_for_filename(file) do
    ["Ethyl", file]
    |> Enum.map(&String.replace(&1, ".", "::"))
    |> Enum.map(&String.replace(&1, "/", "|"))
    |> Enum.join("::")
    |> String.to_atom()
  end
end
