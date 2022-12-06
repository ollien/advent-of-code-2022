defmodule AdventOfCode2022.Solution.Day6 do
  use AdventOfCode2022.Solution

  @impl true
  @spec prepare_input(String.t()) :: String.t()
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
  end

  @impl true
  @spec part1(String.t()) :: number() | :no_match
  def part1(signal) do
    find_marker_position(signal, 4)
  end

  @impl true
  @spec part2(String.t()) :: number() | :no_match
  def part2(signal) do
    find_marker_position(signal, 14)
  end

  @spec find_marker_position(String.t(), number()) :: number() | :no_match
  defp find_marker_position(str, marker_length) do
    find_marker_position(str, marker_length, 0)
  end

  @spec find_marker_position(String.t(), number(), number()) :: number() | :no_match
  defp find_marker_position(str, marker_length, n) do
    marker_end = n + marker_length
    candidate = String.slice(str, n..(marker_end - 1))

    cond do
      String.length(candidate) < marker_length -> :no_match
      all_chars_unique?(candidate) -> marker_end
      true -> find_marker_position(str, marker_length, n + 1)
    end
  end

  @spec all_chars_unique?(String.t()) :: boolean
  defp all_chars_unique?(str) do
    num_unique_chars =
      str
      |> String.codepoints()
      |> Enum.uniq()
      |> Enum.count()

    num_unique_chars == String.length(str)
  end
end
