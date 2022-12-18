defmodule AdventOfCode2022.Solution.Day17 do
  use AdventOfCode2022.Solution

  @type direction :: :left | :right
  @type position :: {number(), number()}

  defmodule Pushes do
    alias AdventOfCode2022.Solution.Day17

    @enforce_keys [:initial, :current]
    defstruct [:initial, :current]

    @type t :: %Pushes{initial: [Day17.direction()], current: [Day17.direction()]}

    def from_list(push_list) do
      %Pushes{initial: push_list, current: []}
    end

    def pop(pushes = %Pushes{current: [next | rest]}) do
      {%{pushes | current: rest}, next}
    end

    def pop(pushes = %Pushes{initial: [next | rest], current: []}) do
      {%{pushes | current: rest}, next}
    end
  end

  @impl true
  @spec prepare_input(String.t()) :: Pushes.t()
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> parse_input!()
    |> Pushes.from_list()
  end

  @impl true
  def part1(pushes) do
    simulate(pushes, 2022)
  end

  @spec simulate(Pushes.t(), number()) :: number()
  defp simulate(pushes, max_piece_idx) do
    floor = for(col <- 0..6, do: {0, col}) |> Enum.into(MapSet.new())
    first_piece = get_piece(0, 0)
    simulate(0, max_piece_idx, first_piece, pushes, floor)
  end

  @spec simulate(
          number(),
          number(),
          [{number(), number()}],
          Pushes.t(),
          MapSet.t({number(), number()})
        ) :: number()
  defp simulate(piece_idx, max_piece_idx, _current_piece, _pushes, placed)
       when piece_idx >= max_piece_idx do
    floor_height(placed)
  end

  defp simulate(piece_idx, max_piece_idx, current_piece, pushes, placed) do
    {next_pushes, push_dir} = Pushes.pop(pushes)
    blown_piece = blow(current_piece, placed, push_dir)

    case move_down(blown_piece, placed) do
      :done ->
        next_placed = Enum.into(blown_piece, placed)
        next_piece = get_piece(piece_idx + 1, floor_height(next_placed))
        simulate(piece_idx + 1, max_piece_idx, next_piece, next_pushes, next_placed)

      {:shifted, shifted} ->
        simulate(piece_idx, max_piece_idx, shifted, next_pushes, placed)
    end
  end

  @spec blow([position()], MapSet.t(position()), direction()) :: [position()]
  defp blow(current_piece, placed, :left) do
    min_col = current_piece |> Enum.map(fn {_row, col} -> col end) |> Enum.min()
    blown = current_piece |> Enum.map(fn {row, col} -> {row, col - 1} end)

    if min_col <= 0 or Enum.any?(blown, &MapSet.member?(placed, &1)) do
      current_piece
    else
      blown
    end
  end

  defp blow(current_piece, placed, :right) do
    max_col = current_piece |> Enum.map(fn {_row, col} -> col end) |> Enum.max()
    blown = current_piece |> Enum.map(fn {row, col} -> {row, col + 1} end)

    if max_col >= 6 or Enum.any?(blown, &MapSet.member?(placed, &1)) do
      current_piece
    else
      blown
    end
  end

  @spec move_down([position()], MapSet.t(position)) :: :done | {:shifted, [position()]}
  defp move_down(current_piece, placed) do
    shifted =
      current_piece
      |> Enum.map(fn {row, col} -> {row - 1, col} end)

    if Enum.any?(shifted, &MapSet.member?(placed, &1)) do
      :done
    else
      {:shifted, shifted}
    end
  end

  @spec floor_height(MapSet.t(position)) :: number()
  defp floor_height(placed) do
    placed
    |> Enum.map(fn {row, _col} -> row end)
    |> Enum.max()
  end

  @spec floor_height(String.t()) :: [direction()]
  defp parse_input!(input) do
    input
    |> String.codepoints()
    |> Enum.map(fn
      "<" -> :left
      ">" -> :right
    end)
  end

  # horizontal piece
  defp get_piece(index, floor_height) when rem(index, 5) == 0 do
    [{0, 2}, {0, 3}, {0, 4}, {0, 5}]
    |> set_piece_height(floor_height)
  end

  # plus piece
  defp get_piece(index, floor_height) when rem(index, 5) == 1 do
    [{-1, 2}, {-1, 3}, {0, 3}, {-2, 3}, {-1, 4}]
    |> set_piece_height(floor_height)
  end

  # backwards L piece
  defp get_piece(index, floor_height) when rem(index, 5) == 2 do
    [{-2, 2}, {-2, 3}, {-2, 4}, {-1, 4}, {0, 4}]
    |> set_piece_height(floor_height)
  end

  # vertical piece
  defp get_piece(index, floor_height) when rem(index, 5) == 3 do
    [{0, 2}, {1, 2}, {2, 2}, {3, 2}]
    |> set_piece_height(floor_height)
  end

  # Block piece
  defp get_piece(index, floor_height) when rem(index, 5) == 4 do
    [{-2, 2}, {-2, 3}, {-1, 2}, {-1, 3}]
    |> set_piece_height(floor_height)
  end

  defp set_piece_height(piece_coords, floor_height) do
    lowest_point =
      piece_coords
      |> Enum.map(fn {row, _col} -> row end)
      |> Enum.min()

    piece_coords
    |> Enum.map(fn {row, col} -> {row - lowest_point + floor_height + 4, col} end)
  end

  # Debug function, left in case anyone needs it
  defp _print_board(placed) do
    max_height = placed |> Enum.map(fn {row, _col} -> row end) |> Enum.max()

    max_height..0
    |> Enum.each(fn row ->
      0..6
      |> Enum.each(fn col ->
        if MapSet.member?(placed, {row, col}) do
          IO.write("#")
        else
          IO.write(".")
        end
      end)

      IO.puts("")
    end)
  end
end
