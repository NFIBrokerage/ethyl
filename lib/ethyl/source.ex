defmodule Ethyl.Source do
  @moduledoc """
  A structure representing a source file containing Ethyl code
  """

  @typedoc """
  """
  @type t :: %__MODULE__{
          path: Path.t(),
          context: Ethyl.Context.t(),
          ast: Macro.t()
        }

  defstruct [:path, :context, :ast]

  def new(path) do
    context = %Ethyl.Context{id: String.to_atom(path)}

    ast =
      path
      |> File.read!()
      |> Code.string_to_quoted!(file: path)
      |> Ethyl.from_elixir_ast(context)

    %__MODULE__{
      path: path,
      context: context,
      ast: ast
    }
  end
end
