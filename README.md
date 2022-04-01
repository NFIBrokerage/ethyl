# Ethyl

![CI](https://github.com/NFIBrokerage/ethyl/workflows/Actions%20CI/badge.svg)

A pure and non-general subset of Elixir

### Status

We've abandoned the Ethyl effort. Needing to restrict the language and change
the behavior of `import/1` is not great, so we tried another approach based
on `khepri`'s
[`khepri_fun`](https://github.com/rabbitmq/khepri/blob/53a8ad8022369b07ccaf34693b0d6b538b51f810/src/khepri_fun.erl),
which is similar in spirit to
[Safeish](https://github.com/robinhilliard/safeish). That effort got much
further but we ended up abandoning that too as writing purely functional
Elixir that never depends on outside values like the current time or the
availability of modules ends up being very unergonomic. In particular, we
would've had to abandon or fork Ecto (it uses dynamic application in a way
that is tough to refactor), and we use Ecto extensively. The takeaways of
this project are still valuable, though. Writing side-effects in a monad-like
fashion where you declare your intent and then a runtime environment commits
the side-effects based on that description works well. (As opposed to
performing side-effects in an imperative manner.) That approach can reduce
boilerplate and simplify testing.

### About

Ethyl is a subset of the Elixir general-purpose programming language written
in Elixir. Ethyl allows one to write purely functional expressions using
Elixir syntax.

Ethyl is closely related to sandboxing efforts like
[`dune`](https://github.com/functional-rewire/dune) or
[`sand`](https://github.com/bopjesvla/sand), but it does not intend on offering
a complete (or even close to complete) or secure implementation of Elixir.
Instead Ethyl is more like [`nix`](https://github.com/NixOS/nix): it puts
forth a language that is powerful enough to compute expressions but not
powerful enough to perform any side effects. For example, you can't run an
HTTP client or server in Ethyl, but you could write functions for encoding
and decoding HTTP packets.

### Purpose

Writing completely purely functional code is not typically useful: at the
end of the day you need to do some IO or else any program will just make
your computer warm and then exit.

Ethyl programs are intended to be called from Elixir so that Elixir passes
in any inputs and handles any outputs. From the example above, an Elixir
program could pass in some data structure representing an HTTP request to
an ethyl program and receive an encoded frame as output.

Ethyl enforces a separation between purely functional code and impure
code. Impure code is oftentimes stateful and/or imperative in nature. Enforcing
a boundary between the two can allow one to switch out conceptual logical cores
of applications separately from the machinery that drives the logic. Because
of their purity, Ethyl programs can be released as fast as they can be
downloaded and evaluated, while general Elixir programs should be compiled
and packaged for a more classical deployment (e.g. a release running on a
Virtual Machine or a Docker container running in an orchestration layer).

### Changes from Elixir

There are a few behavior changes from Elixir built-ins:

- `defmodule/2` returns the module's name instead of a tuple
- `import/1` accepts a binary as an argument, allowing one to import the value
  of a separate Ethyl file by path
    ```elixir
    my_value = import "./my_value.exs"
    ```

There are also some restrictions:

- Networking, file access, processes, and metaprogramming are disabled
    - A more concrete set of functions which are allowed or disallowed is
      planned for the future.
- `:erlang.binary_to_term/1` is disabled
