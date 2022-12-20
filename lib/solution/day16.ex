defmodule AdventOfCode2022.Solution.Day16 do
  use AdventOfCode2022.Solution

  # This solution is slow and messy, but I spent so long on it and I don't really care enough to clean it up anymore.
  # On my machine, part 1 takes 10 seconds (ish) and part 2 takes ~3 minutes and uses a lot of memory

  @type valve :: %{flow_rate: number(), neighbors: [String.t()]}
  @type graph :: %{String.t() => valve()}
  @type state :: %{current_position: String.t(), waiting_for_pressure: number()}
  @type continue_func :: (graph(), MapSet.t(String.t()), :ets.tid() -> number())

  @impl true
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map(&parse_line!/1)
    |> Enum.into(%{})
  end

  @impl true
  def part1(graph) do
    maximize_pressure(graph, :part1)
  end

  @impl true
  def part2(graph) do
    maximize_pressure(graph, :part2)
  end

  @spec maximize_pressure(graph(), :part1 | :part2) :: number()
  defp maximize_pressure(graph, part) do
    memo_ref = :ets.new(:memo, [])

    result =
      maximize_pressure(
        graph,
        %{current_position: "AA", waiting_for_pressure: 0},
        num_steps_for_part(part),
        MapSet.new(),
        num_actors_for_part(part),
        memo_ref,
        continue_func_for_part(part)
      )

    :ets.delete(memo_ref)
    result
  end

  @spec num_steps_for_part(:part1 | :part2) :: number()
  defp num_steps_for_part(:part1), do: 30
  defp num_steps_for_part(:part2), do: 26

  @spec num_actors_for_part(:part1 | :part2) :: number()
  defp num_actors_for_part(:part1), do: 1
  defp num_actors_for_part(:part2), do: 2

  @spec continue_func_for_part(:part1 | :part2) :: continue_func()
  defp continue_func_for_part(:part1), do: fn _graph, _open_valves, _memo_ref -> 0 end

  defp continue_func_for_part(:part2),
    do: fn graph, open_valves, memo_ref ->
      maximize_pressure(
        graph,
        %{current_position: "AA", waiting_for_pressure: 0},
        num_steps_for_part(:part2),
        open_valves,
        num_actors_for_part(:part2) - 1,
        memo_ref,
        fn _graph, _open_valves, _memo_ref -> 0 end
      )
    end

  @spec maximize_pressure(
          graph(),
          state(),
          number(),
          MapSet.t(String.t()),
          number(),
          :ets.tid(),
          continue_func()
        ) ::
          number()
  defp maximize_pressure(
         graph,
         _state,
         steps_left,
         open_valves,
         _num_actors,
         memo_ref,
         continue_func
       )
       when steps_left <= 0 do
    continue_func.(graph, open_valves, memo_ref)
  end

  defp maximize_pressure(
         graph,
         state,
         steps_left,
         open_valves,
         num_actors,
         memo_ref,
         continue_func
       ) do
    memo_value =
      case :ets.lookup(memo_ref, {state, steps_left, :erlang.phash2(open_valves), num_actors}) do
        [{_key, value}] -> value
        [] -> nil
      end

    if memo_value != nil do
      memo_value
    else
      result =
        build_walk_operations(
          graph,
          state,
          steps_left,
          open_valves,
          num_actors,
          memo_ref,
          continue_func
        )
        |> Enum.map(fn op -> op.() end)
        |> Enum.max()

      :ets.insert(
        memo_ref,
        {{state, steps_left, :erlang.phash2(open_valves), num_actors}, result}
      )

      result
    end
  end

  @spec build_walk_operations(
          graph(),
          state(),
          number(),
          MapSet.t(String.t()),
          number(),
          :ets.tid(),
          continue_func()
        ) ::
          [(() -> number())]
  defp build_walk_operations(
         graph,
         state,
         steps_left,
         open_valves,
         num_actors,
         memo_ref,
         continue_func
       ) do
    %{flow_rate: flow_rate, neighbors: neighbors} = Map.get(graph, state.current_position)

    do_next_step = fn ->
      neighbors
      |> Enum.map(fn neighbor ->
        maximize_pressure(
          graph,
          %{state | current_position: neighbor, waiting_for_pressure: 0},
          steps_left - 1,
          open_valves,
          num_actors,
          memo_ref,
          continue_func
        )
      end)
      |> Enum.max()
    end

    cond do
      state.waiting_for_pressure > 0 ->
        local_pressure = state.waiting_for_pressure * steps_left
        # We already opened the valve
        [fn -> local_pressure + do_next_step.() end]

      can_open_valve?(open_valves, state.current_position, flow_rate) ->
        open_valve = fn ->
          maximize_pressure(
            graph,
            %{state | waiting_for_pressure: flow_rate},
            steps_left - 1,
            # "Open" the valve so the two states aren't competing for it
            MapSet.put(open_valves, state.current_position),
            num_actors,
            memo_ref,
            continue_func
          )
        end

        [open_valve, do_next_step]

      true ->
        [do_next_step]
    end
  end

  @spec can_open_valve?(MapSet.t(String.t()), String.t(), number()) :: boolean()
  defp can_open_valve?(open_valves, current_position, local_flow_rate) do
    local_flow_rate > 0 and not MapSet.member?(open_valves, current_position)
  end

  @spec parse_line!(String.t()) :: {String.t(), valve()}
  defp parse_line!(line) do
    pattern =
      ~r/Valve ([A-Z]{2}) has flow rate=(\d+); tunnels? leads? to valves? ((?:[A-Z]{2}(?:, )?)*)/

    [_match, name, flow_rate, raw_neighbors] = Regex.run(pattern, line)
    neighbor_names = String.split(raw_neighbors, ", ")

    {name, %{flow_rate: String.to_integer(flow_rate), neighbors: neighbor_names}}
  end
end
