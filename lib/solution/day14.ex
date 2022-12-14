defmodule AdventOfCode2022.Solution.Day14 do
  use AdventOfCode2022.Solution

  @type position :: {number(), number()}
  @type board :: MapSet.t(position())

  @sand_start_pos {0, 500}

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
      {:ok, _position, board} -> add_sand_until_abyss(board, abyss_row, num_added + 1)
      {:abyss, board} -> {board, num_added}
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
      {:ok, @sand_start_pos, board} ->
        {board, num_added + 1}

      {:ok, _position, board} ->
        add_sand_until_full(board, floor_row, num_added + 1)
    end
  end

  @spec add_sand(board(), {:abyss | :floor, number()}) ::
          {:ok, position(), board()} | {:abyss, board()}
  defp add_sand(board, config) do
    case drop_sand(board, config, @sand_start_pos) do
      {:ok, final_sand_pos} ->
        {:ok, final_sand_pos, MapSet.put(board, final_sand_pos)}

      :abyss ->
        {:abyss, board}
    end
  end

  @spec drop_sand(board(), {:abyss | :floor, number()}, position()) :: {:ok, position()} | :abyss
  defp drop_sand(board, config = {mode, end_row}, {sand_row, sand_col}) do
    empty_at? = fn pos = {row, _col} ->
      case mode do
        :abyss ->
          not MapSet.member?(board, pos)

        :floor when row == end_row ->
          false

        :floor when row < end_row ->
          not MapSet.member?(board, pos)
      end
    end

    cond do
      mode == :abyss and sand_row >= end_row ->
        :abyss

      empty_at?.({sand_row + 1, sand_col}) ->
        drop_sand(board, config, {sand_row + 1, sand_col})

      empty_at?.({sand_row + 1, sand_col - 1}) ->
        drop_sand(board, config, {sand_row + 1, sand_col - 1})

      empty_at?.({sand_row + 1, sand_col + 1}) ->
        drop_sand(board, config, {sand_row + 1, sand_col + 1})

      true ->
        {:ok, {sand_row, sand_col}}
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
