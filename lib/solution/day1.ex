defmodule AdventOfCode2022.Solution.Day1 do
  use AdventOfCode2022.Solution

  @impl true
  @spec prepare_input(String.t()) :: [[number]]
  def prepare_input(input_filename) do
    File.read!(input_filename)
    |> String.split("\n")
    |> Enum.map(&parse_line!/1)
    |> group_elves()
  end

  @impl true
  @spec part1([[number]]) :: number
  def part1(elves) do
    Enum.map(elves, &Enum.sum/1)
    |> Enum.max()
  end

  @impl true
  @spec part2([[number]]) :: number
  def part2(elves) do
    Enum.map(elves, &Enum.sum/1)
    |> Enum.sort()
    |> Enum.reverse()
    |> Enum.take(3)
    |> Enum.sum()
  end

  @spec parse_line!(String.t()) :: number | :blank
  defp parse_line!("") do
    :blank
  end

  defp parse_line!(line) do
    String.to_integer(line)
  end

  @spec group_elves([number | :blank]) :: [[number]]
  defp group_elves(input_lines) do
    Enum.chunk_by(input_lines, &(&1 != :blank))
    # chunk_by will produce runs of elements that produce the same value, and for a well-formed
    # input, we will just see [:blank] wherever there is a blank line, so we can filter it out
    |> Enum.filter(&(&1 != [:blank]))
  end
end
