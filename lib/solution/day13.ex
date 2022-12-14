defmodule AdventOfCode2022.Solution.Day13 do
  alias AdventOfCode2022.Solution.Day13.ListParser
  use AdventOfCode2022.Solution

  @type input_list :: [number() | input_list()]
  @type comparison :: :greater | :equal | :less

  @impl true
  def prepare_input(input) do
    File.read!(input)
    |> String.trim_trailing()
    |> String.split("\n\n")
    |> Enum.map(&parse_list_pair!/1)
  end

  @impl true
  @spec part1([{input_list(), input_list()}]) :: number()
  def part1(pairs) do
    pairs
    |> Enum.map(fn {a, b} -> compare(a, b) end)
    |> Enum.with_index()
    |> Enum.filter(fn {comparison_res, _index} -> comparison_res == :less end)
    |> Enum.map(fn {_comparison_res, index} -> index + 1 end)
    |> Enum.sum()
  end

  @impl true
  @spec part2([{input_list(), input_list()}]) :: number()
  def part2(pairs) do
    packets = Enum.flat_map(pairs, &Tuple.to_list/1)
    divider_packets = [[[2]], [[6]]]

    (divider_packets ++ packets)
    |> Enum.sort(fn pair1, pair2 -> compare(pair1, pair2) != :greater end)
    |> Enum.with_index()
    |> Enum.filter(fn {value, _idx} -> Enum.member?(divider_packets, value) end)
    |> Enum.map(fn {_value, index} -> index + 1 end)
    |> Enum.product()
  end

  @spec compare(number() | input_list(), number() | input_list()) :: comparison()
  defp compare(a, b) when is_integer(a) and is_integer(b) do
    cond do
      a < b -> :less
      a == b -> :equal
      a > b -> :greater
    end
  end

  defp compare(a, b) when is_integer(a) and is_list(b) do
    compare([a], b)
  end

  defp compare(a, b) when is_list(a) and is_integer(b) do
    compare(a, [b])
  end

  defp compare(a, b) when is_list(a) and is_list(b) do
    case compare_lists_as_equal_size(a, b) do
      :equal when length(a) > length(b) -> :greater
      :equal when length(a) < length(b) -> :less
      :equal -> :equal
      :greater -> :greater
      :less -> :less
    end
  end

  # Compare two lists, truncating the longer of the two to be the length of the former
  @spec compare_lists_as_equal_size(input_list(), input_list()) :: comparison()
  defp compare_lists_as_equal_size(a, b) when is_list(a) and is_list(b) do
    Enum.zip(a, b)
    |> Enum.reduce_while(
      :equal,
      fn {a_elem, b_elem}, :equal ->
        case compare(a_elem, b_elem) do
          :greater -> {:halt, :greater}
          :less -> {:halt, :less}
          :equal -> {:cont, :equal}
        end
      end
    )
  end

  @spec parse_list_pair!(String.t()) :: {input_list(), input_list()}
  defp parse_list_pair!(raw_pair) do
    [list1, list2] = String.split(raw_pair, "\n")

    {
      parse_list!(list1),
      parse_list!(list2)
    }
  end

  @spec parse_list!(String.t()) :: input_list()
  defp parse_list!(raw_list) do
    {:ok, [list], "", _, _, _} = ListParser.list(raw_list)
    list
  end

  defmodule ListParser do
    import NimbleParsec

    def into_list([]) do
      []
    end

    def into_list(elements = [_head | _rest]) do
      # This is a weird quirk of NimbleParsec, but you can actually just return the list itself, and
      # the reduced result will actually come back as the passed list!
      elements
    end

    list_element =
      choice([
        integer(min: 1),
        parsec(:listp)
      ])

    list =
      ignore(string("["))
      |> optional(
        list_element
        |> repeat(
          ignore(string(","))
          |> concat(list_element)
        )
      )
      |> ignore(string("]"))
      |> reduce(:into_list)

    defcombinatorp(:listp, list)

    defparsec(:list, parsec(:listp) |> eos)
  end
end
