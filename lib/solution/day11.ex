defmodule AdventOfCode2022.Solution.Day11 do
  use AdventOfCode2022.Solution

  @type monkey :: %{
          items: [number()],
          operation: (number() -> number()),
          divisor: number(),
          truthy_destination: number(),
          falsy_destination: number()
        }

  @type monkeys :: %{number() => monkey()}

  @impl true
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n\n")
    |> Enum.map(&parse_monkey!/1)
    |> Enum.into(%{})
  end

  @impl true
  def part1(monkeys) do
    suppressed_worry_monkeys =
      monkeys
      |> Enum.map(fn {monkey_id, monkey = %{operation: operation}} ->
        updated_operation = &(operation.(&1) |> div(3))
        {monkey_id, Map.put(monkey, :operation, updated_operation)}
      end)
      |> Enum.into(%{})

    simulate(suppressed_worry_monkeys, 20)
  end

  @impl true
  def part2(monkeys) do
    simulate(monkeys, 10000)
  end

  @spec simulate(monkeys(), number()) :: number()
  defp simulate(monkeys, num_rounds) do
    inspection_counts =
      1..num_rounds
      |> Enum.reduce(
        %{monkeys: monkeys, inspection_counts: %{}},
        fn _round_num, %{monkeys: result_monkeys, inspection_counts: result_inspection_counts} ->
          %{monkeys: monkeys, inspection_counts: inspection_counts} = run_round(result_monkeys)

          %{
            monkeys: monkeys,
            inspection_counts:
              combine_maps(inspection_counts, result_inspection_counts, &Kernel.+/2, 0)
          }
        end
      )
      |> Map.get(:inspection_counts)

    [top1_count, top2_count] =
      Map.values(inspection_counts)
      |> Enum.sort()
      |> Enum.reverse()
      |> Enum.take(2)

    top1_count * top2_count
  end

  @spec run_round(monkeys()) :: %{
          monkeys: monkeys(),
          inspection_counts: %{number() => number()}
        }
  defp run_round(monkeys) do
    # For part 2 to work. I hate this, and never would have figured it out.
    # https://www.reddit.com/r/adventofcode/comments/zifqmh/comment/izrd7iz/?utm_source=reddit&utm_medium=web2x&context=3
    best_divisor =
      monkeys
      |> Map.values()
      |> Enum.map(& &1.divisor)
      |> Enum.product()

    Map.keys(monkeys)
    |> Enum.reduce(
      %{monkeys: monkeys, inspection_counts: %{}},
      fn monkey_id, %{monkeys: result_monkeys, inspection_counts: inspection_counts} ->
        monkey = Map.get(result_monkeys, monkey_id)
        item_destinations = inspect_monkey_items(monkey, best_divisor)
        inspection_count = Enum.count(monkey.items)

        updated_inspection_counts =
          Map.update(inspection_counts, monkey_id, inspection_count, fn count ->
            count + inspection_count
          end)

        monkey_without_items = Map.update!(monkey, :items, fn _value -> [] end)

        updated_monkeys =
          Enum.reduce(
            item_destinations,
            %{result_monkeys | monkey_id => monkey_without_items},
            fn {destination, item}, monkeys ->
              throw_item!(monkeys, item, destination)
            end
          )

        %{monkeys: updated_monkeys, inspection_counts: updated_inspection_counts}
      end
    )
  end

  @spec inspect_monkey_items(monkey(), number()) :: [{number(), number()}]
  defp inspect_monkey_items(monkey, best_divisor) do
    monkey.items
    |> Enum.map(fn item -> perform_item_inspection(monkey, item, best_divisor) end)
  end

  @spec perform_item_inspection(monkey(), number(), number()) :: {number(), number()}
  defp perform_item_inspection(monkey, item, best_divisor) do
    next_worry_level = rem(monkey.operation.(item), best_divisor)

    if rem(next_worry_level, monkey.divisor) == 0 do
      {monkey.truthy_destination, next_worry_level}
    else
      {monkey.falsy_destination, next_worry_level}
    end
  end

  @spec combine_maps(
          map1 :: %{key => value},
          map2 :: %{key => value},
          combine_func :: (value, value -> t),
          default :: value
        ) :: %{key => t}
        when key: any(), value: any(), t: any()
  defp combine_maps(map1, map2, combine_func, default) do
    Enum.map(map1, fn {key, value1} ->
      value2 = Map.get(map2, key, default)
      {key, combine_func.(value1, value2)}
    end)
    |> Enum.into(%{})
  end

  defp throw_item!(monkeys, item, destination) do
    update_in(monkeys, [destination, :items], fn items -> [item | items] end)
  end

  @spec parse_monkey!(String.t()) :: {number(), monkey()}
  defp parse_monkey!(raw_monkey) do
    [
      id_line,
      starting_item_line,
      operation_line,
      test_line,
      truthy_destination_line,
      falsy_destination_line
    ] = String.split(raw_monkey, "\n")

    id = parse_monkey_id!(id_line)

    monkey = %{
      items: parse_monkey_starting_items!(starting_item_line),
      operation: parse_monkey_operation!(operation_line),
      divisor: parse_monkey_divisor!(test_line),
      truthy_destination: parse_truthy_destination!(truthy_destination_line),
      falsy_destination: parse_falsy_destination!(falsy_destination_line)
    }

    {id, monkey}
  end

  @spec parse_monkey_id!(String.t()) :: number()
  defp parse_monkey_id!(id_line) do
    [_match, monkey_number] = Regex.run(~r/^Monkey (\d+):$/, id_line)
    String.to_integer(monkey_number)
  end

  @spec parse_monkey_starting_items!(String.t()) :: [number()]
  defp parse_monkey_starting_items!(starting_items_line) do
    [_match, starting_items] =
      Regex.run(~r/^\s*Starting items: ((?:\d+(?:,\s)?)+)/, starting_items_line)

    starting_items
    |> String.split(", ")
    |> Enum.map(&String.to_integer/1)
  end

  @spec parse_monkey_operation!(String.t()) :: (number() -> number())
  defp parse_monkey_operation!(operation_line) do
    [_match, operator, operand] =
      Regex.run(~r"^\s*Operation: new = old ([+\-*\/]) (\d+|old)$", operation_line)

    operand_fn =
      case operand do
        "old" ->
          fn n -> n end

        numeric_operand ->
          parsed_operand = String.to_integer(numeric_operand)
          fn _n -> parsed_operand end
      end

    case operator do
      "+" -> &(&1 + operand_fn.(&1))
      "-" -> &(&1 - operand_fn.(&1))
      "*" -> &(&1 * operand_fn.(&1))
      "/" -> &(&1 / operand_fn.(&1))
    end
  end

  @spec parse_monkey_divisor!(String.t()) :: number()
  defp parse_monkey_divisor!(test_line) do
    [_match, raw_divisor] = Regex.run(~r/^\s*Test: divisible by (\d+)$/, test_line)

    String.to_integer(raw_divisor)
  end

  @spec parse_truthy_destination!(String.t()) :: number()
  defp parse_truthy_destination!(destination_line) do
    [_match, raw_destination] =
      Regex.run(~r/^\s*If true: throw to monkey (\d+)$/, destination_line)

    String.to_integer(raw_destination)
  end

  @spec parse_falsy_destination!(String.t()) :: number()
  defp parse_falsy_destination!(destination_line) do
    [_match, raw_destination] =
      Regex.run(~r/^\s*If false: throw to monkey (\d+)$/, destination_line)

    String.to_integer(raw_destination)
  end
end
