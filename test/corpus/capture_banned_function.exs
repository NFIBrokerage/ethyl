(&DateTime.utc_now/0).()
(&:erlang.binary_to_term/1).(<<>>)
(&apply/3).(DateTime, :utc_now, [])
(&apply(&1, :utc_now, [])).(DateTime)
import DateTime
(&utc_now/0).()
# note: not an import, just getting coverage :P
(&foo/0).()
