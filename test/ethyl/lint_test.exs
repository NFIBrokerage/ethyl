defmodule Ethyl.LintTest do
  use ExUnit.Case, async: true

  alias Ethyl.{Lint, Source}

  describe "a pass of linting produces expected lints" do
    test "given a program with unsafe function calls" do
      fixture = Source.new("test/corpus/disallowed_function_calls.exs")
      assert [a, b, c, d] = Lint.lint(fixture)
      assert a.description =~ "File.read!/1"
      assert b.description =~ "DateTime.utc_now/0"
      assert c.description =~ "Kernel.send/2"
      assert d.description =~ "Kernel.self/0"
    end

    test "given a program that imports a program with unsafe function calls" do
      fixture = Source.new("test/corpus/import_disallowed.exs")
      # each file should be linted distinctly, nothing is wrong with a file
      # that just imports another file
      assert Lint.lint(fixture) == []
    end

    test "given a program uses imports to get around banned functions" do
      fixture = Source.new("test/corpus/import_hack.exs")
      assert lints = Lint.lint(fixture)
      assert length(lints) == 2

      for lint <- lints do
        assert lint.description =~ "is not an allowed function call"
      end
    end

    test "given a program uses multiple imports to get around banned functions" do
      fixture = Source.new("test/corpus/multi_import.exs")
      assert [lint] = Lint.lint(fixture)
      # note: later imports take precedence
      assert lint.description =~ "NaiveDateTime.utc_now/0"
    end

    test "given a program uses apply/3 to get around banned functions" do
      fixture = Source.new("test/corpus/apply_banned_function.exs")
      assert [a, b, c] = Lint.lint(fixture)
      assert a.description =~ "DateTime.utc_now/0"
      assert b.description =~ ":erlang.binary_to_term/1"
      # dynamic apply is not expanded, but caught by the linter
      assert c.description =~ "Kernel.apply/3"
    end

    test "given a program uses function captures to get around banned functions" do
      fixture = Source.new("test/corpus/capture_banned_function.exs")
      assert [a, b, c, d, e] = Lint.lint(fixture)
      assert a.description =~ "DateTime.utc_now/0"
      assert b.description =~ ":erlang.binary_to_term/1"
      assert c.description =~ "Kernel.apply/3"
      assert d.description =~ "Kernel.apply/3"
      assert e.description =~ "DateTime.utc_now/0"
    end

    test "given a program uses bindings to get around banned functions" do
      fixture = Source.new("test/corpus/dynamic_function_application.exs")
      assert [a, b] = Lint.lint(fixture)
      assert a.description =~ "module.utc_now()"
      assert b.description =~ "module.read!"
    end
  end

  test "all good fixtures survive linting" do
    for path <- Path.wildcard("test/corpus/good/*.exs") do
      fixture = Source.new(path)
      assert Lint.lint(fixture) == []
    end
  end
end
