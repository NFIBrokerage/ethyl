# Ethyl

A pure and non-general subset of Elixir

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
    my_value = import "my_value.exs"
    ```

There are also some restrictions:

- Networking, file access, processes, and metaprogramming are disabled
    - A more concrete set of functions which are allowed or disallowed is
      planned for the future.
- `:erlang.binary_to_term/1` is disabled
