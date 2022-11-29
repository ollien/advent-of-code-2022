defmodule AdventOfCode2022.Solution do
  @callback prepare_input(input_filename :: String.t()) :: any()

  @callback part1(input :: any()) :: String.Chars.t()
  @callback part2(input :: any()) :: String.Chars.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour AdventOfCode2022.Solution
      @before_compile AdventOfCode2022.Solution
    end
  end

  defmacro __before_compile__(env) do
    unless Module.defines?(env.module, {:prepare_input, 1}) do
      quote do
        def prepare_input(input_filename), do: input_filename
      end
    end

    unless Module.defines?(env.module, {:part1, 1}) do
      IO.warn(
        "function part1/1 not implemented in module #{inspect(env.module)}. Providing empty implementation."
      )

      quote do
        def part1(input), do: :no_impl
      end
    end

    unless Module.defines?(env.module, {:part2, 1}) do
      IO.warn(
        "function part2/1 not implemented in module #{inspect(env.module)}. Providing empty implementation."
      )

      quote do
        def part2(input), do: :no_impl
      end
    end
  end

  # https://stackoverflow.com/questions/55434550/check-that-module-implements-behaviour
  def implemented_by?(module) do
    :attributes
    |> module.module_info()
    |> Enum.member?({:behaviour, [__MODULE__]})
  end
end
