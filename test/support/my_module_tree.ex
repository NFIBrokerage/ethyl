defmodule MyModuleTree do
  @moduledoc false
  defmodule Foo do
    @moduledoc false
    def foo, do: :foo

    defmodule Bar do
      @moduledoc false
      def bar, do: :bar

      defmodule Baz do
        @moduledoc false
        def baz, do: :baz
      end
    end
  end
end
