defmodule AdventOfCode2022.Solution.Day14 do
  use AdventOfCode2022.Solution

  @type position :: {number(), number()}
  @type board :: MapSet.t(position())

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
  def part1(board) do
    {_board, num_added} = add_sand_until_abyss(board)
    num_added
  end

  @spec add_sand_until_abyss(board()) :: {board(), number()}
  def add_sand_until_abyss(board) do
    add_sand_until_abyss(board, 0)
  end

  @spec add_sand_until_abyss(board(), number) :: {board, number()}
  def add_sand_until_abyss(board, num_added) do
    case add_sand(board) do
      {:ok, board} -> add_sand_until_abyss(board, num_added + 1)
      {:abyss, board} -> {board, num_added}
    end
  end

  @spec add_sand(board()) :: {:ok, board()} | {:abyss, board()}
  def add_sand(board) do
    case drop_sand(board, {0, 500}) do
      {:ok, final_sand_pos} ->
        {:ok, MapSet.put(board, final_sand_pos)}

      :abyss ->
        {:abyss, board}
    end
  end

  @spec drop_sand(board(), position()) :: {:ok, position()} | :abyss
  def drop_sand(board, sand_pos) do
    {abyss_row, _floor_col} = MapSet.to_list(board) |> Enum.max_by(fn {row, _col} -> row end)
    drop_sand(board, abyss_row + 1, sand_pos)
  end

  @spec drop_sand(board(), number(), position()) :: {:ok, position()} | :abyss
  def drop_sand(board, abyss_row, {sand_row, sand_col}) do
    cond do
      sand_row >= abyss_row ->
        :abyss

      not MapSet.member?(board, {sand_row + 1, sand_col}) ->
        drop_sand(board, {sand_row + 1, sand_col})

      not MapSet.member?(board, {sand_row + 1, sand_col - 1}) ->
        drop_sand(board, {sand_row + 1, sand_col - 1})

      not MapSet.member?(board, {sand_row + 1, sand_col + 1}) ->
        drop_sand(board, {sand_row + 1, sand_col + 1})

      true ->
        {:ok, {sand_row, sand_col}}
    end
  end

  @spec parse_coord!(String.t()) :: [position()]
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
