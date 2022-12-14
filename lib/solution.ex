defmodule AdventOfCode2022.Solution do
  @callback prepare_input(input_filename :: String.t()) :: any()
  @callback part1(input :: any()) :: String.Chars.t()
  @callback part2(input :: any()) :: String.Chars.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)
      @before_compile unquote(__MODULE__)

      def prepare_input(input_filename), do: {:error, :no_impl}

      defoverridable prepare_input: 1
    end
  end

  defmacro __before_compile__(env) do
    quote do
      unquote(
        unless(Module.defines?(env.module, {:part1, 1})) do
          IO.warn(
            "function part1/1 not implemented in module #{inspect(env.module)}. Providing empty implementation.",
            env
          )

          quote do
            def part1(input), do: :no_impl
          end
        end
      )

      unquote(
        unless Module.defines?(env.module, {:part2, 1}) do
          IO.warn(
            "function part2/1 not implemented in module #{inspect(env.module)}. Providing empty implementation.",
            env
          )

          quote do
            def part2(input), do: :no_impl
          end
        end
      )
    end
  end

  # https://stackoverflow.com/questions/55434550/check-that-module-implements-behaviour
  def implemented_by?(module) do
    :attributes
    |> module.module_info()
    |> Enum.member?({:behaviour, [__MODULE__]})
  end
end
