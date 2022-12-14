defmodule AdventOfCode2022.Solution.Day14 do
  use AdventOfCode2022.Solution

  @type position :: {number(), number()}
  @type board :: MapSet.t(position())
  @type mode :: :abyss | :floor
  @type config :: {mode(), number()}

  @sand_start_position {0, 500}

  @impl true
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map(&parse_rock_line!/1)
    |> List.flatten()
    |> Enum.into(MapSet.new())
  end

  @impl true
  @spec part1(board()) :: number()
  def part1(board) do
    {_board, num_added} = add_sand_until_abyss(board)
    num_added
  end

  @impl true
  @spec part2(board()) :: number()
  def part2(board) do
    {_board, num_added} = add_sand_until_full(board)
    num_added
  end

  @spec add_sand_until_abyss(board()) :: {board(), number()}
  defp add_sand_until_abyss(board) do
    {bottom_row, _col} = MapSet.to_list(board) |> Enum.max_by(fn {row, _col} -> row end)
    abyss_row = bottom_row + 1

    add_sand_until_abyss(board, abyss_row, 0)
  end

  @spec add_sand_until_abyss(board(), number(), number()) :: {board, number()}
  defp add_sand_until_abyss(board, abyss_row, num_added) do
    case add_sand(board, {:abyss, abyss_row}) do
      {:ok, _position, board} ->
        add_sand_until_abyss(board, abyss_row, num_added + 1)

      {:abyss, board} ->
        {board, num_added}
    end
  end

  @spec add_sand_until_full(board(), number(), number()) :: {board, number()}
  defp add_sand_until_full(board) do
    {bottom_row, _col} = MapSet.to_list(board) |> Enum.max_by(fn {row, _col} -> row end)
    floor_row = bottom_row + 2

    add_sand_until_full(board, floor_row, 0)
  end

  defp add_sand_until_full(board, floor_row, num_added) do
    case add_sand(board, {:floor, floor_row}) do
      {:ok, @sand_start_position, board} ->
        {board, num_added + 1}

      {:ok, _position, board} ->
        add_sand_until_full(board, floor_row, num_added + 1)
    end
  end

  @spec add_sand(board(), config) ::
          {:ok, position(), board()} | {:abyss, board()}
  defp add_sand(board, config) do
    case drop_sand(board, config, @sand_start_position) do
      {:ok, final_sand_position} ->
        {:ok, final_sand_position, MapSet.put(board, final_sand_position)}

      :abyss ->
        {:abyss, board}
    end
  end

  @spec drop_sand(board(), config, position()) :: {:ok, position()} | :abyss
  defp drop_sand(board, config, sand_position) do
    case get_next_drop_move(board, config, sand_position) do
      {:cont, next_position} -> drop_sand(board, config, next_position)
      {:halt, :abyss} -> :abyss
      {:halt, ending_position} -> {:ok, ending_position}
    end
  end

  @spec get_next_drop_move(board, config, position()) ::
          {:cont, position()} | {:halt, position()} | {:halt, :abyss}
  defp get_next_drop_move(_board, {:abyss, end_row}, {sand_row, _sand_col})
       when sand_row >= end_row do
    {:halt, :abyss}
  end

  defp get_next_drop_move(board, config, sand_position = {sand_row, sand_col}) do
    possible_positions = [
      {sand_row + 1, sand_col},
      {sand_row + 1, sand_col - 1},
      {sand_row + 1, sand_col + 1}
    ]

    # Fun tidbit: This `find` call is about 250ms slower than just chaining a `cond` with the possible positions
    # on  my machine, but is IMO more readable as-is.
    case Enum.find(possible_positions, &can_drop_to(board, config, &1)) do
      nil -> {:halt, sand_position}
      next_position -> {:cont, next_position}
    end
  end

  @spec can_drop_to(board, config, position()) :: boolean()
  defp can_drop_to(board, {:abyss, _end_row}, sand_position) do
    not MapSet.member?(board, sand_position)
  end

  defp can_drop_to(board, {:floor, end_row}, sand_position = {sand_row, _sand_col}) do
    # It is not valid sand_row to be > end_row, as this is an infinite floor, so we will only consider
    # the == and < cases
    cond do
      sand_row == end_row -> false
      sand_row < end_row -> not MapSet.member?(board, sand_position)
    end
  end

  @spec parse_rock_line!(String.t()) :: [position()]
  defp parse_rock_line!(line) do
    line
    |> String.split(" -> ")
    |> Enum.map(&parse_coord!/1)
    |> Enum.chunk_every(2, 1)
    # Drop the last element, which is just the last coordinate, not a 2 element chunk
    |> Enum.drop(-1)
    |> Enum.flat_map(fn [coord1, coord2] -> expand_coord_range(coord1, coord2) end)
    |> Enum.uniq()
  end

  @spec parse_coord!(String.t()) :: position()
  defp parse_coord!(coord) do
    [x, y] = String.split(coord, ",") |> Enum.map(&String.to_integer/1)
    {y, x}
  end

  defp expand_coord_range({row1, col1}, {row2, col2}) when row1 == row2 do
    col1..col2
    |> Enum.map(&{row1, &1})
  end

  defp expand_coord_range({row1, col1}, {row2, col2}) when col1 == col2 do
    row1..row2
    |> Enum.map(&{&1, col1})
  end
end
