defmodule AdventOfCode2022.Solution.Day0 do
  use AdventOfCode2022.Solution

  @impl true
  def prepare_input(filename) do
    String.reverse(filename)
  end

  @impl true
  def part1(filename) do
    String.upcase(filename)
  end
end
