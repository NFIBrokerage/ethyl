defmodule Ethyl.Lint do
  @moduledoc """
  Functions for linting Ethyl code
  """

  @known_linters [
    Ethyl.Lint.MfaAllowlist
  ]

  @type t :: %__MODULE__{}

  defstruct [:linter, :file, :line, :description]

  @callback lint(source :: Ethyl.Source.t()) :: [t()]

  @doc """
  Lints a source file against all known linters
  """
  def lint(source) do
    Enum.flat_map(@known_linters, & &1.lint(source))
  end

  @doc """
  Traverses the AST in search of lint issues

  This function uses `Macro.prewalk/3` under the hood. The `traversal_fn`
  must be a function of arity 2 taking the AST and the accumulator as arguments.
  `traversal_fn` should return a 2-tuple of `{ast, lints}`
  """
  def traverse(source, traversal_fn, acc \\ [])

  def traverse(%Ethyl.Source{} = source, traversal_fn, acc)
      when is_function(traversal_fn, 2) do
    traverse(source.ast, traversal_fn, acc)
  end

  def traverse(source, traversal_fn, acc)
      when is_tuple(source) and is_function(traversal_fn, 2) do
    {_new_ast, new_acc} =
      Macro.prewalk(source, acc, &{&1, traversal_fn.(&1, &2)})

    new_acc
  end
end
