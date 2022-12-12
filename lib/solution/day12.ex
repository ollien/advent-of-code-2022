defmodule AdventOfCode2022.Solution.Day12 do
  use AdventOfCode2022.Solution

  @type graph :: %{number() => %{number() => char()}}
  @type position :: {number(), number()}

  @impl true
  def prepare_input(filename) do
    graph =
      File.read!(filename)
      |> String.trim_trailing()
      |> String.split("\n")
      |> parse_graph()

    # print_graph(graph)
    graph
  end

  @impl true
  @spec part1(graph) :: number()
  def part1(graph) do
    [starting_position] = find_starting_positions(graph, [?S])
    find_shortest_num_steps(graph, starting_position)
  end

  @impl true
  @spec part2(graph) :: number()
  def part2(graph) do
    find_starting_positions(graph, [?a, ?S])
    |> Enum.map(fn starting_pos ->
      # I didn't feel like being smart and writing an algorithm that would just explore the whole graph
      # so I just used concurrency :)
      Task.async(fn -> find_shortest_num_steps(graph, starting_pos) end)
    end)
    |> Task.await_many()
    |> Enum.min()
  end

  @spec find_starting_positions(graph(), [char()]) :: [position()]
  defp find_starting_positions(graph, allowed_chars) do
    graph
    |> Enum.map(fn {line_idx, line} ->
      find_starting_positions_in_line(line, allowed_chars)
      |> Enum.map(fn col -> {line_idx, col} end)
    end)
    |> List.flatten()
  end

  @spec find_starting_positions_in_line(graph(), [char()]) :: [number()]
  defp find_starting_positions_in_line(graph_line, allowed_chars) do
    graph_line
    |> Enum.filter(fn {_key, value} -> Enum.member?(allowed_chars, value) end)
    |> Enum.map(&Kernel.elem(&1, 0))
  end

  @spec find_shortest_num_steps(graph(), position()) :: number()
  defp find_shortest_num_steps(graph, starting_pos) do
    find_shortest_num_steps(
      graph,
      :queue.in({0, starting_pos}, :queue.new()),
      [starting_pos] |> Enum.into(MapSet.new())
    )
  end

  @spec find_shortest_num_steps(
          graph(),
          :queue.queue({number(), position()}),
          MapSet.t(number())
        ) :: number()
  defp find_shortest_num_steps(_graph, {[], []}, _visited) do
    # There is no shortest path if we've reached the end without finding E
    nil
  end

  defp find_shortest_num_steps(graph, to_visit, visited) do
    {{:value, {depth, visiting_pos}}, popped_to_visit} = :queue.out(to_visit)
    {visiting_row, visiting_col} = visiting_pos
    visiting_value = get_in(graph, [visiting_row, visiting_col])

    if visiting_value == ?E do
      depth
    else
      {next_to_visit, next_visited} =
        get_neighbors(graph, visiting_pos)
        |> Enum.filter(fn {position, value} ->
          not MapSet.member?(visited, position) and can_traverse_to?(visiting_value, value)
        end)
        |> Enum.reduce(
          {popped_to_visit, visited},
          fn {neighbor_pos, _neighbor_value}, {memo_to_visit, memo_visited} ->
            {
              :queue.in({depth + 1, neighbor_pos}, memo_to_visit),
              MapSet.put(memo_visited, neighbor_pos)
            }
          end
        )

      find_shortest_num_steps(graph, next_to_visit, next_visited)
    end
  end

  @spec can_traverse_to?(char(), char()) :: boolean()
  defp can_traverse_to?(?S, next_value) do
    can_traverse_to?(?a, next_value)
  end

  defp can_traverse_to?(current_value, ?E) do
    can_traverse_to?(current_value, ?z)
  end

  defp can_traverse_to?(current_value, next_value) do
    current_value >= next_value or next_value - current_value == 1
  end

  @spec get_neighbors(graph, position()) :: [{position(), char()}]
  defp get_neighbors(graph, position) do
    get_neighbor_candidates(position)
    |> Enum.map(fn position = {row, col} -> {position, get_in(graph, [row, col])} end)
    |> Enum.filter(fn {_position, value} -> value != nil end)
  end

  @spec get_neighbor_candidates(position()) :: [position()]
  defp get_neighbor_candidates({row, col}) do
    [
      {row - 1, col},
      {row + 1, col},
      {row, col - 1},
      {row, col + 1}
    ]
  end

  @spec parse_graph([String.t()]) :: graph()
  defp parse_graph(input_lines) do
    input_lines
    |> Enum.map(&parse_graph_line/1)
    |> Enum.with_index()
    |> Enum.map(fn {value, idx} -> {idx, value} end)
    |> Enum.into(%{})
  end

  @spec parse_graph_line(String.t()) :: %{number() => char()}
  defp parse_graph_line(input_line) do
    input_line
    |> String.to_charlist()
    |> Enum.with_index()
    |> Enum.map(fn {value, idx} -> {idx, value} end)
    |> Enum.into(%{})
  end

  defp print_graph(graph) do
    graph
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Enum.each(fn {_idx, line} -> print_graph_line(line) end)
  end

  defp print_graph_line(graph_line) do
    graph_line
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Enum.map(fn {_key, char} -> char end)
    |> IO.puts()
  end
end
