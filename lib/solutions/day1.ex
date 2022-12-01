defmodule AdventOfCode2022.Solution.Day1 do
  use AdventOfCode2022.Solution

  @impl true
  @spec prepare_input(String.t()) :: [[number]]
  def prepare_input(input_filename) do
    File.read!(input_filename)
    |> String.split("\n")
    |> Enum.map(&parse_line/1)
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

  defp parse_line("") do
    ""
  end

  defp parse_line(line) do
    case Integer.parse(line) do
      {n, ""} -> n
    end
  end

  defp group_elves(input_lines) do
    Enum.chunk_by(input_lines, &(&1 != ""))
    |> Enum.filter(&(&1 != [""]))
  end
end
