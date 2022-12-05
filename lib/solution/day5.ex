defmodule AdventOfCode2022.Solution.Day5 do
  use AdventOfCode2022.Solution

  @type move :: %{quantity: number, from: number, to: number}
  @type stack :: [String.t()]

  @impl true
  @spec prepare_input(String.t()) :: {[stack()], [move()]}
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n\n")
    |> parse_input!()
  end

  @impl true
  @spec part1({[stack()], [move()]}) :: String.t()
  def part1(input) do
    solve(input, &run_simple_move/2)
  end

  @impl true
  @spec part2({[stack()], [move()]}) :: String.t()
  def part2(input) do
    solve(input, &run_advanced_move/2)
  end

  @spec solve(
          input :: {[stack()], [move()]},
          move_func :: (stacks :: [stack()], move :: move() -> [stack()])
        ) :: String.t()
  def solve({stacks, moves}, move_func) do
    moves
    |> Enum.reduce(stacks, fn move, current_stacks ->
      move_func.(current_stacks, move)
    end)
    |> Enum.map(fn
      [head | _rest] -> head
      [] -> ""
    end)
    |> Enum.join()
  end

  defp parse_input!([stacks, moves]) do
    parsed_stacks =
      stacks
      |> String.split("\n")
      |> parse_stacks!()

    parsed_moves =
      moves
      |> String.split("\n")
      |> parse_moves!()

    {parsed_stacks, parsed_moves}
  end

  @spec parse_moves!(stack()) :: [move()]
  def parse_moves!(moves) do
    Enum.map(moves, &parse_move!/1)
  end

  @spec parse_move!(String.t()) :: move()
  def parse_move!(move) do
    [_match, quantity, from, to] = Regex.run(~r/move (\d+) from (\d+) to (\d+)/, move)

    %{
      quantity: String.to_integer(quantity),
      from: String.to_integer(from),
      to: String.to_integer(to)
    }
  end

  @spec parse_stacks!(stack()) :: [stack()]
  def parse_stacks!(stacks) do
    num_stacks =
      stacks
      |> Enum.find(&is_index_row?/1)
      |> get_num_stacks_from_index_row()

    stacks
    |> Enum.take_while(fn line -> not is_index_row?(line) end)
    |> Enum.reverse()
    |> Enum.map(&parse_container_row!/1)
    |> build_stacks!(num_stacks)
  end

  @spec is_index_row?(String.t()) :: boolean
  defp is_index_row?(line) do
    Regex.match?(~r/(\s?\d+\s?)+/, line)
  end

  @spec get_num_stacks_from_index_row(String.t()) :: number
  defp get_num_stacks_from_index_row(index_row) do
    index_row
    |> String.split(" ")
    |> Enum.filter(fn s -> String.length(s) > 0 end)
    |> Enum.count()
  end

  @spec parse_container_row!(String.t()) :: [String.t() | nil]
  defp parse_container_row!(container_row) do
    Regex.scan(~r/(?:(\s{3})|\[([A-Z])\])\s?/, container_row)
    |> Enum.map(fn
      [_match, "   "] -> nil
      [_match, "", letter] -> letter
    end)
  end

  # build_stacks takes a list of parsed container rows and stacks them on top of each other to produce a list of stacks
  @spec build_stacks!([[String.t() | nil]], number) :: [stack()]
  defp build_stacks!(parsed_container_rows, num_stacks) do
    # assert that all rows have the same length
    true = Enum.all?(parsed_container_rows, fn row -> Enum.count(row) == num_stacks end)
    stacks = List.duplicate([], num_stacks)

    parsed_container_rows
    |> Enum.reduce(stacks, &stack_container_row/2)
  end

  def stack_container_row(container_row, stacks) do
    Enum.zip(container_row, stacks)
    |> Enum.map(fn
      {nil, existing} -> existing
      {new, existing} -> [new | existing]
    end)
  end

  @spec run_simple_move([stack()], move()) :: [stack()]
  defp run_simple_move(stacks, move) do
    from = move.from - 1
    to = move.to - 1
    from_stack = Enum.at(stacks, from)
    to_stack = Enum.at(stacks, to)

    {new_from, new_to} =
      1..move.quantity
      |> Enum.reduce({from_stack, to_stack}, fn _idx, {[from_head | from_rest], to_stack} ->
        {from_rest, [from_head | to_stack]}
      end)

    transplant_stacks(stacks, {new_from, from}, {new_to, to})
  end

  @spec run_advanced_move([stack()], move()) :: [stack()]
  defp run_advanced_move(stacks, move) do
    from = move.from - 1
    to = move.to - 1
    from_stack = Enum.at(stacks, from)
    to_stack = Enum.at(stacks, to)

    {from_top, from_bottom} = Enum.split(from_stack, move.quantity)
    new_from = from_bottom
    new_to = from_top ++ to_stack
    transplant_stacks(stacks, {new_from, from}, {new_to, to})
  end

  @spec transplant_stacks(
          stacks :: [stack()],
          {stack(), number()},
          {stack(), number()}
        ) :: [stack()]
  defp transplant_stacks(current_stacks, {new_from, from_idx}, {new_to, to_idx}) do
    current_stacks
    |> Enum.with_index()
    |> Enum.map(fn
      {_stack, ^from_idx} -> new_from
      {_stack, ^to_idx} -> new_to
      {stack, _idx} -> stack
    end)
  end
end
