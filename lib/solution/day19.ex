# This takes 7 minutes on my machine, and quite a bit of memory (~15G at peak) at that. I spent so long on this I don't feel like
# findinf more heuristics to optimize it more

defmodule AdventOfCode2022.Solution.Day19 do
  use AdventOfCode2022.Solution
  @type ingredient :: :ore | :clay | :obsidian | :geode
  @type input :: {number(), ingredient()}
  @type blueprint :: %{ingredient() => input()}
  @type inventory :: %{ingredient() => number()}
  @type state :: %{
          robots: inventory(),
          items: inventory(),
          time_left: number()
        }

  @impl true
  @spec prepare_input(String.t()) :: [blueprint()]
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map(&parse_blueprint!/1)
  end

  @impl true
  def part1(blueprints) do
    blueprints
    |> Enum.with_index(1)
    |> Task.async_stream(
      fn {blueprint, idx} ->
        output = simulate(blueprint, 24)
        {output, idx}
      end,
      timeout: :infinity
    )
    |> Enum.map(fn {:ok, result} -> result end)
    |> Enum.map(fn {output, idx} -> output * idx end)
    |> Enum.sum()
  end

  @impl true
  def part2(blueprints) do
    blueprints
    |> Enum.take(3)
    |> Task.async_stream(
      fn blueprint ->
        simulate(blueprint, 32)
      end,
      timeout: :infinity
    )
    |> Enum.map(fn {:ok, result} -> result end)
    |> Enum.product()
  end

  @spec simulate(blueprint(), number()) :: number()
  defp simulate(blueprint, num_steps) do
    max_resources_per_turn = highest_cost_by_resource(blueprint)
    visited_ets = :ets.new(:visited, [])

    simulate(
      blueprint,
      [%{time_left: num_steps, robots: %{ore: 1}, items: %{}}],
      nil,
      visited_ets,
      max_resources_per_turn
    )
  end

  defp simulate(_blueprint, [], %{items: items}, _visited, _memo) do
    Map.get(items, :geode, 0)
  end

  @spec simulate(blueprint(), [state()], state() | nil, :ets.tab(), %{ingredient() => number()}) ::
          number()
  defp simulate(
         blueprint,
         states_to_simulate = [state | rest_to_simulate],
         best_state,
         visited,
         max_resources_per_turn
       ) do
    :ets.insert(visited, {visited_key(state), true})

    cond do
      best_possible_geodes(state) < num_geodes_in_state(best_state) ->
        do_simulation(
          blueprint,
          rest_to_simulate,
          best_state,
          visited,
          max_resources_per_turn
        )

      true ->
        do_simulation(
          blueprint,
          states_to_simulate,
          best_state,
          visited,
          max_resources_per_turn
        )
    end
  end

  @spec do_simulation(blueprint(), [state()], state() | nil, :ets.tab(), %{
          ingredient() => number()
        }) ::
          number()
  defp do_simulation(
         blueprint,
         [],
         best_state,
         visited,
         max_resources_per_turn
       ) do
    simulate(blueprint, [], best_state, visited, max_resources_per_turn)
  end

  defp do_simulation(
         blueprint,
         [state = %{time_left: 0} | rest_to_simulate],
         best_state,
         visited,
         max_resources_per_turn
       ) do
    next_best_state = pick_best_state(state, best_state)

    simulate(blueprint, rest_to_simulate, next_best_state, visited, max_resources_per_turn)
  end

  defp do_simulation(
         blueprint,
         [
           state = %{items: items, robots: robots, time_left: time_left}
           | rest_to_simulate
         ],
         best_state,
         visited,
         max_resources_per_turn
       ) do
    buildable =
      buildable_robots(items, blueprint)
      |> filter_build_stage(robots, max_resources_per_turn)

    next_states =
      [:build_nothing | buildable]
      |> Enum.map(fn
        :build_nothing ->
          next_inventory =
            collect_resources(items, robots)
            |> compress_inventory(max_resources_per_turn, time_left)

          %{state | items: next_inventory, time_left: time_left - 1}

        resource ->
          next_inventory =
            build_robot!(blueprint, resource, items)
            |> collect_resources(robots)
            |> compress_inventory(max_resources_per_turn, time_left)

          next_robots = Map.update(robots, resource, 1, fn count -> count + 1 end)

          %{state | items: next_inventory, robots: next_robots, time_left: time_left - 1}
      end)
      |> Enum.reject(fn state ->
        case :ets.lookup(visited, visited_key(state)) do
          [_element] -> true
          [] -> false
        end
      end)

    simulate(
      blueprint,
      next_states ++ rest_to_simulate,
      best_state,
      visited,
      max_resources_per_turn
    )
  end

  @spec pick_best_state(state() | nil, state() | nil) :: state()
  defp pick_best_state(state, nil) do
    state
  end

  # Dialyezr complains that this first arg is never nil but removing it seems wrong
  @dialyzer {:no_match, pick_best_state: 2}
  defp pick_best_state(nil, state) do
    state
  end

  defp pick_best_state(state1, state2) do
    [state1, state2]
    |> Enum.max_by(fn %{items: items} -> Map.get(items, :geode, 0) end)
  end

  @spec num_geodes_in_state(state() | nil) :: number()
  defp num_geodes_in_state(nil) do
    0
  end

  defp num_geodes_in_state(%{items: items}) do
    Map.get(items, :geode, 0)
  end

  # I stole this trick from reddit. We can save a ton of states by compressing the inventory to
  # only as many resources as we could possibly use
  @spec compress_inventory(inventory(), %{ingredient() => number()}, number()) :: number()
  defp compress_inventory(inventory, max_cost_per_turn, time_left) do
    inventory
    |> Enum.map(fn {resource, count} ->
      case Map.get(max_cost_per_turn, resource) do
        nil -> {resource, count}
        max_cost -> {resource, min(count, max_cost * time_left)}
      end
    end)
    |> Enum.into(%{})
  end

  # Also stole this one from reddit. Don't build more robots for a given resource than that which produce
  # the max number of resources we can consume on a single turn. For instance, if at most we can spend 10
  # clay on a single turn, there is no reason to have more than 10 clay robots.
  @spec compress_inventory([ingredient()], [ingredient()], %{ingredient() => number()}) ::
          number()
  defp filter_build_stage(buildable_robots, active_robots, max_cost_per_turn) do
    buildable_robots
    |> Enum.filter(fn type ->
      num_robots_of_type = Map.get(active_robots, type, 0)

      case Map.get(max_cost_per_turn, type) do
        nil -> true
        type_max_cost -> num_robots_of_type <= type_max_cost
      end
    end)
  end

  # @spec best_possible_geodes(state()) :: number()
  defp best_possible_geodes(%{items: items, robots: robots, time_left: time_left}) do
    num_geodes_from_inventory = Map.get(items, :geode, 0)
    num_geodes_from_robots = Map.get(robots, :geode, 0) * time_left
    best_possible_extra_geodes = time_left * (time_left + 1) / 2

    num_geodes_from_inventory + num_geodes_from_robots + best_possible_extra_geodes
  end

  @spec collect_resources(inventory(), inventory()) :: inventory()
  defp collect_resources(inventory, robots) do
    robots
    |> Enum.reduce(inventory, fn {resource, count}, acc_inventory ->
      Map.update(
        acc_inventory,
        resource,
        count,
        fn current_count -> current_count + count end
      )
    end)
  end

  @spec buildable_robots(inventory, blueprint) :: [ingredient()]
  defp buildable_robots(inventory, blueprint) do
    blueprint
    |> Enum.filter(fn {_resource, costs} ->
      can_build_robot?(costs, inventory)
    end)
    |> Enum.map(fn {resource, _cost} -> resource end)
  end

  defp can_build_robot?(resource_costs, inventory) do
    resource_costs
    |> Enum.all?(fn {cost, resource} ->
      case Map.get(inventory, resource) do
        nil -> false
        quantity -> quantity >= cost
      end
    end)
  end

  @spec build_robot!(blueprint(), ingredient(), inventory()) :: inventory()
  defp build_robot!(blueprint, type, inventory) do
    Map.get(blueprint, type)
    |> Enum.reduce(inventory, fn {cost, resource}, acc_inventory ->
      Map.update!(acc_inventory, resource, fn current when current >= cost -> current - cost end)
    end)
  end

  defp visited_key(%{items: items, robots: robots, time_left: time_left}) do
    %{items: items, robots: robots, time_left: time_left}
  end

  @spec parse_blueprint!(String.t()) :: blueprint()
  defp parse_blueprint!(raw_blueprint) do
    [_name, ingredients] = String.split(raw_blueprint, ": ")

    ingredients
    |> String.split(". ")
    |> Enum.map(&parse_robot!/1)
    |> Enum.into(%{})
  end

  defp highest_cost_by_resource(blueprint) do
    blueprint
    |> Map.values()
    |> List.flatten()
    |> Enum.reduce(%{}, fn {cost, resource}, max_spend_acc ->
      Map.update(max_spend_acc, resource, cost, fn
        current_value when current_value > cost -> current_value
        _ -> cost
      end)
    end)
  end

  @spec parse_robot!(String.t()) :: {ingredient(), [input()]}
  defp parse_robot!(ingredient_line) do
    pattern = ~r/Each ([a-z]+) robot costs (.+)/
    [_match, output, inputs] = Regex.run(pattern, ingredient_line)
    {parse_ingredient_type!(output), parse_robot_inputs!(inputs)}
  end

  @spec parse_robot_inputs!(String.t()) :: [input()]
  defp parse_robot_inputs!(inputs) do
    inputs
    |> String.split(" and ")
    |> Enum.map(&parse_robot_input!/1)
  end

  @spec parse_robot_input!(String.t()) :: input()
  defp parse_robot_input!(input) do
    pattern = ~r/(\d+) ([a-z]+)/
    [_match, quantity, ingredient] = Regex.run(pattern, input)
    {String.to_integer(quantity), parse_ingredient_type!(ingredient)}
  end

  @spec parse_ingredient_type!(String.t()) :: ingredient()
  defp parse_ingredient_type!(ingredient) do
    case ingredient do
      "ore" -> :ore
      "clay" -> :clay
      "obsidian" -> :obsidian
      "geode" -> :geode
    end
  end
end
