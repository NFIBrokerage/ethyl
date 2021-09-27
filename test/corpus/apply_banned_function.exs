apply(DateTime, :utc_now, [])
apply(:erlang, :binary_to_term, [<<>>])
mod = DateTime
apply(mod, :utc_now, [])
