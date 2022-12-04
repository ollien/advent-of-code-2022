defmodule AdventOfCode2022.Solution.Day4 do
  use AdventOfCode2022.Solution

  @impl true
  @spec prepare_input(String.t()) :: [{number(), number()}]
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map(&parse_line!/1)
  end

  @impl true
  @spec part1([{number(), number()}]) :: number()
  def part1(ranges) do
    Enum.count(ranges, fn [range1, range2] ->
      fully_overlap?(range1, range2)
    end)
  end

  @impl true
  @spec part2([{number(), number()}]) :: number()
  def part2(ranges) do
    Enum.count(ranges, fn [range1, range2] ->
      partially_overlap?(range1, range2)
    end)
  end

  @spec parse_line!(String.t()) :: [{number(), number()}]
  defp parse_line!(line) do
    String.split(line, ",")
    |> Enum.map(&parse_range!/1)
  end

  @spec parse_range!(String.t()) :: {number(), number()}
  defp parse_range!(range) do
    [range_start, range_end] =
      range
      |> String.split("-")
      |> Enum.map(&String.to_integer/1)

    {range_start, range_end}
  end

  @spec fully_overlap?({number(), number()}, {number(), number()}) :: boolean()
  defp fully_overlap?({start1, end1}, {start2, end2}) when end1 >= start1 and end2 >= start2 do
    (start1 <= start2 and end1 >= end2) or (start1 >= start2 and end1 <= end2)
  end

  @spec partially_overlap?({number(), number()}, {number(), number()}) :: boolean()
  defp partially_overlap?({start1, end1}, {start2, end2})
       when end1 >= start1 and end2 >= start2 do
    # If they're not disjoint, they partially overlap
    not (start1 > end2 or start2 > end1)
  end
end
