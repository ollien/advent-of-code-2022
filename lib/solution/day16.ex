defmodule AdventOfCode2022.Solution.Day16 do
  use AdventOfCode2022.Solution

  @type valve :: %{flow_rate: number(), neighbors: [String.t()]}
  @type graph :: %{String.t() => valve()}
  @type state :: %{current_position: String.t(), waiting_for_pressure: number()}

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
    maximize_pressure(graph)
  end

  @spec maximize_pressure(graph()) :: number()
  defp maximize_pressure(graph) do
    {:ok, memo_pid} = Agent.start(fn -> %{} end)

    maximize_pressure(
      graph,
      %{current_position: "AA", waiting_for_pressure: 0},
      30,
      MapSet.new(),
      memo_pid
    )
  end

  @spec maximize_pressure(graph(), state(), number(), MapSet.t(String.t()), Agent.agent()) ::
          number()
  defp maximize_pressure(_graph, _state, steps_left, _open_valves, _memo_pid)
       when steps_left <= 0 do
    0
  end

  defp maximize_pressure(
         graph,
         state,
         steps_left,
         open_valves,
         memo_pid
       ) do
    memo_value =
      Agent.get(memo_pid, fn memo ->
        Map.get(memo, {state, steps_left, open_valves})
      end)

    if memo_value != nil do
      memo_value
    else
      result =
        build_walk_operations(graph, state, steps_left, open_valves, memo_pid)
        |> Enum.map(fn op -> op.() end)
        |> Enum.max()

      Agent.update(memo_pid, fn memo ->
        Map.put(memo, {state, steps_left, open_valves}, result)
      end)

      result
    end
  end

  @spec build_walk_operations(graph(), state(), number(), MapSet.t(String.t()), Agent.agent()) ::
          [(() -> number())]
  defp build_walk_operations(graph, state, steps_left, open_valves, memo_pid) do
    %{flow_rate: flow_rate, neighbors: neighbors} = Map.get(graph, state.current_position)

    do_next_step = fn ->
      neighbors
      |> Enum.map(fn neighbor ->
        maximize_pressure(
          graph,
          %{state | current_position: neighbor, waiting_for_pressure: 0},
          steps_left - 1,
          open_valves,
          memo_pid
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
            memo_pid
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
