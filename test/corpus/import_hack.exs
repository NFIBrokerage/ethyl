import DateTime
utc_now()
import :erlang, only: [binary_to_term: 1]

binary_to_term(
  <<131, 100, 0, 15, 69, 108, 105, 120, 105, 114, 46, 68, 97, 116, 101, 84, 105,
    109, 101>>
)
