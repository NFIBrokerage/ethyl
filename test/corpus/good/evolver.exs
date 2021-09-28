defmodule Evolver do
  def evolve(events, initial_state) when is_list(events) do
    Enum.reduce(events, initial_state, &evolve/2)
  end

  def evolve(_event, state) do
    update_in(state.counter, &(&1 + 1))
  end
end

&Evolver.evolve/2
