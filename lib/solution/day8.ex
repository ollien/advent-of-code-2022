defmodule AdventOfCode2022.Solution.Day8 do
  use AdventOfCode2022.Solution

  @type grid :: [[number()]]

  @impl true
  @spec prepare_input(String.t()) :: grid()
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map(fn line -> String.codepoints(line) |> Enum.map(&String.to_integer(&1)) end)
  end

  @impl true
  @spec part1(grid()) :: number
  def part1(grid) do
    externally_visible_indexes(grid)
    |> Enum.uniq()
    |> Enum.count()
  end

  @impl true
  @spec part2(grid()) :: number
  def part2(grid) do
    build_scenic_score_table(grid)
    |> Enum.max_by(&Enum.max/1)
    |> Enum.max()
  end

  @spec externally_visible_indexes(grid()) :: [{number(), number()}]
  defp externally_visible_indexes(grid) do
    visible_from_left =
      grid
      |> Enum.with_index(fn row, index ->
        externally_visible_indexes_in_row(row) |> Enum.map(&{index, &1})
      end)
      |> List.flatten()

    # In all cases except the left one, we have to either reverse, transpose, or both, the grid in order to scan
    # "left to right"
    visible_from_right =
      grid
      |> Enum.map(&Enum.reverse/1)
      |> Enum.with_index(fn row, index ->
        externally_visible_indexes_in_row(row) |> Enum.map(&{index, length(row) - &1 - 1})
      end)
      |> List.flatten()

    visible_from_top =
      grid
      |> transpose()
      |> Enum.with_index(fn column, index ->
        externally_visible_indexes_in_row(column) |> Enum.map(&{&1, index})
      end)
      |> List.flatten()

    visible_from_bottom =
      grid
      |> transpose()
      |> Enum.map(&Enum.reverse/1)
      |> Enum.with_index(fn column, index ->
        externally_visible_indexes_in_row(column) |> Enum.map(&{length(column) - &1 - 1, index})
      end)
      |> List.flatten()

    visible_from_left ++ visible_from_right ++ visible_from_top ++ visible_from_bottom
  end

  @spec externally_visible_indexes_in_row([number()]) :: [number()]
  # Scan left to right in order to find the indexes of the trees that are externally visible
  defp externally_visible_indexes_in_row([first_tree | other_trees]) do
    %{visible: visible} =
      Enum.reduce(
        other_trees,
        # The first tree of a row will always be visible, so we skip that one and check the others
        %{last_visible: first_tree, idx: 1, visible: [0]},
        fn
          tree_height, %{last_visible: last_visible, idx: idx, visible: visible}
          when tree_height > last_visible ->
            %{last_visible: tree_height, idx: idx + 1, visible: [idx | visible]}

          _tree_height, state = %{idx: idx} ->
            # We don't want to halt here - there may be a taller tree if we keep looking
            Map.put(state, :idx, idx + 1)
        end
      )

    visible
  end

  @spec build_scenic_score_table(grid) :: [[number]]
  defp build_scenic_score_table(grid) do
    left_visibility_table =
      grid
      |> build_visibility_table()

    # Again, we must transform the rows in order to scan left to right
    right_visibility_table =
      grid
      |> Enum.map(&Enum.reverse/1)
      |> build_visibility_table()
      |> Enum.map(&Enum.reverse/1)

    up_visibility_table =
      grid
      |> transpose()
      |> build_visibility_table()
      # Reverse our transposition
      |> transpose()

    down_visibility_table =
      grid
      |> transpose()
      |> Enum.map(&Enum.reverse/1)
      |> build_visibility_table()
      # Reverse our transposition and reversal
      |> Enum.map(&Enum.reverse/1)
      |> transpose()

    Enum.zip([
      left_visibility_table,
      right_visibility_table,
      up_visibility_table,
      down_visibility_table
    ])
    |> Enum.map(fn rows ->
      Tuple.to_list(rows)
      |> List.zip()
      |> Enum.map(fn {left, right, up, down} -> left * right * up * down end)
    end)
  end

  # Build a "visibility" table. In other words, we scan left to right in each row to determine how far right
  # we can see from each position
  @spec build_visibility_table(grid) :: [[number]]
  defp build_visibility_table(grid) do
    Enum.map(grid, &build_visibility_row/1)
  end

  @spec build_visibility_row([number()]) :: [[number()]]
  defp build_visibility_row(row) do
    %{output: output} =
      Enum.reduce(row, %{output: [], remaining_row: row}, fn
        _, %{output: output, remaining_row: [tree | to_check]} ->
          %{
            output: [get_visibility(tree, to_check) | output],
            remaining_row: to_check
          }
      end)

    Enum.reverse(output)
  end

  @spec get_visibility(number(), [number()]) :: number()
  defp get_visibility(tree, rightward_trees) do
    rightward_trees
    |> Enum.reduce_while(0, fn
      neighbor, visibility when neighbor >= tree -> {:halt, visibility + 1}
      _neighbor, visibility -> {:cont, visibility + 1}
    end)
  end

  # https://stackoverflow.com/questions/23705074/is-there-a-transpose-function-in-elixir
  @spec transpose(grid()) :: grid()
  defp transpose(grid) do
    grid
    |> List.zip()
    |> Enum.map(&Tuple.to_list/1)
  end
end
