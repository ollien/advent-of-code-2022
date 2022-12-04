defmodule AdventOfCode2022.Solution.Day3 do
  use AdventOfCode2022.Solution

  @impl true
  @spec prepare_input(String.t()) :: [String.t()]
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n")
  end

  @impl true
  @spec part1([String.t()]) :: number()
  def part1(rucksacks) do
    rucksacks
    |> Enum.map(&make_compartments/1)
    |> Enum.map(fn {compartment1, compartment2} ->
      {:ok, common_char} = find_common_char([compartment1, compartment2])
      get_priority(common_char)
    end)
    |> Enum.sum()
  end

  @impl true
  @spec part2([String.t()]) :: number()
  def part2(rucksacks) do
    rucksacks
    |> Enum.chunk_every(3)
    |> Enum.map(fn group ->
      {:ok, common_char} = find_common_char(group)
      get_priority(common_char)
    end)
    |> Enum.sum()
  end

  @spec make_compartments(String.t()) :: {String.t(), String.t()}
  defp make_compartments(str) do
    split_point = String.length(str) |> div(2)
    String.split_at(str, split_point)
  end

  @spec find_common_char([String.t()]) ::
          {:ok, String.t()} | {:error, :no_common_element | :more_than_one_common_element}
  defp find_common_char(strings) when length(strings) > 1 do
    common_set =
      strings
      |> Enum.map(&String.codepoints/1)
      |> Enum.map(&Enum.into(&1, MapSet.new()))
      |> Enum.reduce(&MapSet.intersection(&1, &2))

    case MapSet.to_list(common_set) do
      [common_element] -> {:ok, common_element}
      [] -> {:error, :no_common_element}
      _ -> {:error, :more_than_one_common_element}
    end
  end

  @spec get_priority(String.t()) :: number()
  defp get_priority(<<char::binary-size(1)>>) do
    [codepoint] = char |> String.downcase() |> String.to_charlist()
    downcase_priority = codepoint - ?a + 1

    if String.downcase(char) == char do
      downcase_priority
    else
      downcase_priority + 26
    end
  end
end
