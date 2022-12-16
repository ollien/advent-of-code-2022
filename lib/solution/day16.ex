defmodule AdventOfCode2022.Solution.Day16 do
  use AdventOfCode2022.Solution
  require IEx

  @type valve :: %{flow_rate: number(), neighbors: [String.t()]}
  @type graph :: %{String.t() => valve()}

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
    maximize_pressure(graph, "AA", 30, MapSet.new(), memo_pid)
  end

  @spec maximize_pressure(graph(), String.t(), number(), MapSet.t(String.t()), Agent.agent()) ::
          number()
  defp maximize_pressure(_graph, _current_position, steps_left, _open_valves, _memo_pid)
       when steps_left <= 0 do
    0
  end

  defp maximize_pressure(graph, current_position, steps_left, open_valves, memo_pid)
       when steps_left > 0 do
    %{flow_rate: flow_rate, neighbors: neighbors} = Map.get(graph, current_position)

    memo_value =
      Agent.get(memo_pid, fn memo ->
        Map.get(memo, {current_position, steps_left, open_valves})
      end)

    do_next_step = fn next_steps_left, now_open_valves ->
      neighbors
      |> Enum.map(fn neighbor ->
        maximize_pressure(
          graph,
          neighbor,
          next_steps_left,
          now_open_valves,
          memo_pid
        )
      end)
      |> Enum.max()
    end

    cond do
      memo_value != nil ->
        memo_value

      can_open_valve?(open_valves, current_position, flow_rate) ->
        # Don't count the step in which we open the valve in here
        local_pressure = (steps_left - 1) * flow_rate
        now_open_valves = MapSet.put(open_valves, current_position)

        result =
          max(
            local_pressure + do_next_step.(steps_left - 2, now_open_valves),
            do_next_step.(steps_left - 1, open_valves)
          )

        Agent.update(memo_pid, fn memo ->
          Map.put(memo, {current_position, steps_left, open_valves}, result)
        end)

        result

      true ->
        result = do_next_step.(steps_left - 1, open_valves)

        Agent.update(memo_pid, fn memo ->
          Map.put(memo, {current_position, steps_left, open_valves}, result)
        end)

        result
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
