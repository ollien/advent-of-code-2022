defmodule AdventOfCode2022.Solution.Day9 do
  use AdventOfCode2022.Solution

  @type direction :: :right | :left | :up | :down
  @type move :: {direction, number()}
  @type position :: {number(), number()}
  @type rope :: %{head: position(), tail: position()}

  @impl true
  @spec prepare_input(String.t()) :: [move()]
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map(&parse_move!/1)
  end

  @impl true
  @spec part1([move]) :: number()
  def part1(moves) do
    starting_position = %{head: {0, 0}, tail: {0, 0}}

    moves
    |> Enum.reduce(
      [starting_position],
      fn move, positions = [current_position | _rest] ->
        visited_positions = perform_move(current_position, move)
        visited_positions ++ positions
      end
    )
    |> Enum.map(fn %{tail: tail_pos} -> tail_pos end)
    |> Enum.uniq()
    |> Enum.count()
  end

  @spec parse_move!(String.t()) :: move()
  defp parse_move!(line) do
    [raw_direction, raw_count] = String.split(line, " ")

    {parse_direction!(raw_direction), String.to_integer(raw_count)}
  end

  @spec parse_direction!(String.t()) :: direction()
  defp parse_direction!("R"), do: :right
  defp parse_direction!("L"), do: :left
  defp parse_direction!("U"), do: :up
  defp parse_direction!("D"), do: :down

  @spec perform_move(rope(), move()) :: [rope()]
  defp perform_move(rope_position, {direction, count}) do
    1..count
    |> Enum.reduce([rope_position], fn _idx,
                                       positions = [
                                         %{head: head_position, tail: tail_position} | _rest
                                       ] ->
      next_head_position = perform_move_step(head_position, direction)
      next_tail_position = move_tail(next_head_position, tail_position)
      next_position = %{head: next_head_position, tail: next_tail_position}
      [next_position | positions]
    end)
  end

  @spec move_tail(position(), position()) :: position
  defp move_tail({head_row, head_col}, tail_position = {tail_row, tail_col})
       when (head_col == tail_col and abs(head_row - tail_row) == 1) or
              (head_row == tail_row and abs(head_col - tail_col) == 1) or
              (abs(head_col - tail_col) == 1 and abs(head_row - tail_row) == 1) do
    # The tail stays put if it's touching in any direction
    tail_position
  end

  defp move_tail({head_row, head_col}, {tail_row, tail_col})
       when head_col == tail_col and abs(head_row - tail_row) == 2 do
    # The tail stays put if it's touching in any direction
    {tail_row + sign(head_row - tail_row), tail_col}
  end

  defp move_tail({head_row, head_col}, {tail_row, tail_col})
       when head_row == tail_row and abs(head_col - tail_col) == 2 do
    {tail_row, tail_col + sign(head_col - tail_col)}
  end

  defp move_tail({head_row, head_col}, {tail_row, tail_col}) do
    {
      tail_row + sign(head_row - tail_row),
      tail_col + sign(head_col - tail_col)
    }
  end

  @spec perform_move_step(position(), direction()) :: position()
  defp perform_move_step(position, direction) do
    adjust_position(position, {direction, 1})
  end

  @spec adjust_position(position(), move()) :: position()
  defp adjust_position({row, col}, {:up, count}), do: {row + count, col}
  defp adjust_position({row, col}, {:down, count}), do: {row - count, col}
  defp adjust_position({row, col}, {:left, count}), do: {row, col - count}
  defp adjust_position({row, col}, {:right, count}), do: {row, col + count}

  defp sign(n) when n < 0, do: -1
  defp sign(n) when n > 0, do: 1
  defp sign(0), do: 0
end
