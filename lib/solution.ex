defmodule AdventOfCode2022.Solution do
  alias AdventOfCode2022.Solution

  @callback prepare_input(input_filename :: String.t()) :: any()
  @callback part1(input :: any()) :: String.Chars.t()
  @callback part2(input :: any()) :: String.Chars.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour AdventOfCode2022.Solution

      def prepare_input(input_filename), do: input_filename
      def part1(input), do: :no_impl
      def part2(input), do: :no_impl

      defoverridable Solution
    end
  end

  # https://stackoverflow.com/questions/55434550/check-that-module-implements-behaviour
  def implemented_by?(module) do
    :attributes
    |> module.module_info()
    |> Enum.member?({:behaviour, [__MODULE__]})
  end
end
