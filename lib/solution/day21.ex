defmodule AdventOfCode2022.Solution.Day21 do
  use AdventOfCode2022.Solution

  @type operation :: :add | :sub | :mul | :div
  @type branch :: {:entry, entry()} | {:value, number()}
  @type entry :: %{left: String.t(), operation: operation(), right: String.t()}
  @type tree :: %{String.t() => branch()}

  @root_branch_name "root"
  @human_branch_name "humn"

  @impl true
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map(&parse_line!/1)
    |> Enum.into(%{})
  end

  @impl true
  def part1(monkeys) do
    evaluate_monkey(monkeys, @root_branch_name)
    |> round_if_almost_whole()
  end

  @impl true
  def part2(monkeys) do
    collapsed = collapse_monkey_only_branches(monkeys)
    {:entry, %{left: left_name, right: right_name}} = collapsed[@root_branch_name]

    # In a collapsed tree, the one side will have a value, and the other will have an operation
    solved_value =
      case {collapsed[left_name], collapsed[right_name]} do
        {{:value, value}, {:entry, _entry}} -> value
        {{:entry, _entry}, {:value, value}} -> value
      end

    collapsed
    |> build_solve_stack()
    |> Enum.reduce(solved_value, fn operation_func, value ->
      operation_func.(value)
    end)
    |> round_if_almost_whole()
  end

  defp round_if_almost_whole(value) do
    if abs(value - round(value)) < 1.0e-5 do
      value
      |> round()
      |> trunc()
    else
      value
    end
  end

  @spec evaluate_monkey(tree(), String.t()) :: number()
  defp evaluate_monkey(monkeys, name) do
    case monkeys[name] do
      {:value, value} -> value
      {:entry, entry} -> evaluate_entry(monkeys, entry)
    end
  end

  @spec evaluate_monkey(tree(), entry()) :: number()
  defp evaluate_entry(monkeys, %{left: left, right: right, operation: operation}) do
    operation_func = get_operation_func(operation)
    left_value = evaluate_monkey(monkeys, left)
    right_value = evaluate_monkey(monkeys, right)

    operation_func.(left_value, right_value)
  end

  @spec get_operation_func(operation()) :: (number(), number() -> number())
  defp get_operation_func(:add), do: &Kernel.+/2
  defp get_operation_func(:sub), do: &Kernel.-/2
  defp get_operation_func(:mul), do: &Kernel.*/2
  defp get_operation_func(:div), do: &Kernel.//2

  @spec invert_operation(operation()) :: operation()
  defp invert_operation(:add), do: :sub
  defp invert_operation(:sub), do: :add
  defp invert_operation(:mul), do: :div
  defp invert_operation(:div), do: :mul

  @spec collapse_monkey_only_branches(tree()) :: tree()
  defp collapse_monkey_only_branches(monkeys) do
    collapse_monkey_only_branches(monkeys, @root_branch_name)
  end

  @spec collapse_monkey_only_branches(tree(), String.t()) :: tree()
  defp collapse_monkey_only_branches(monkeys, branch_name) do
    collapse_monkey_only_branches(monkeys, branch_name, monkeys[branch_name])
  end

  @spec collapse_monkey_only_branches(tree(), String.t(), branch()) :: tree()
  defp collapse_monkey_only_branches(monkeys, _branch_name, {:value, _value}) do
    monkeys
  end

  defp collapse_monkey_only_branches(
         monkeys,
         branch_name,
         {:entry, %{left: left_branch_name, operation: operation, right: right_branch_name}}
       ) do
    left_evaluated = evaluate_branch_if_monkey_only(monkeys, left_branch_name)
    right_evaluated = evaluate_branch_if_monkey_only(monkeys, right_branch_name)

    case {left_evaluated, right_evaluated} do
      {left_value, nil} ->
        Map.update!(monkeys, left_branch_name, fn _current -> {:value, left_value} end)
        |> collapse_monkey_only_branches(right_branch_name)

      {nil, right_value} ->
        Map.update!(monkeys, right_branch_name, fn _current -> {:value, right_value} end)
        |> collapse_monkey_only_branches(left_branch_name)

      {left_value, right_value} ->
        operation_func = get_operation_func(operation)

        Map.update!(
          monkeys,
          branch_name,
          fn _current -> {:value, operation_func.(left_value, right_value)} end
        )
    end
  end

  @spec evaluate_branch_if_monkey_only(tree(), String.t()) :: number() | nil
  defp evaluate_branch_if_monkey_only(_monkeys, @human_branch_name) do
    nil
  end

  defp evaluate_branch_if_monkey_only(monkeys, branch_name) do
    if branch_has_human(monkeys, monkeys[branch_name]) do
      nil
    else
      evaluate_monkey(monkeys, branch_name)
    end
  end

  @spec branch_has_human(tree(), branch()) :: boolean()
  defp branch_has_human(_monkeys, {:entry, %{left: @human_branch_name}}) do
    true
  end

  defp branch_has_human(_monkeys, {:entry, %{right: @human_branch_name}}) do
    true
  end

  defp branch_has_human(_monkeys, {:value, _value}) do
    false
  end

  defp branch_has_human(monkeys, {:entry, entry}) do
    %{left: left_branch_name, right: right_branch_name} = entry

    branch_has_human(monkeys, monkeys[left_branch_name]) or
      branch_has_human(monkeys, monkeys[right_branch_name])
  end

  @spec build_solve_stack(tree()) :: [(number() -> number())]
  defp build_solve_stack(collapsed_monkeys) do
    {:entry, %{left: left_name, right: right_name}} = collapsed_monkeys[@root_branch_name]

    # In a collapsed tree, the one side will have a value, and the other will have an operation
    cursor =
      case {collapsed_monkeys[left_name], collapsed_monkeys[right_name]} do
        {{:value, _value}, {:entry, _entry}} -> right_name
        {{:entry, _value}, {:value, _entry}} -> left_name
      end

    build_solve_stack(collapsed_monkeys, cursor, [])
    |> Enum.reverse()
  end

  @spec build_solve_stack(tree(), String.t(), [(number() -> number())]) :: [
          (number() -> number())
        ]
  defp build_solve_stack(collapsed_monkeys, cursor, stack) do
    {:entry, %{left: left_name, operation: operation, right: right_name}} =
      collapsed_monkeys[cursor]

    case {collapsed_monkeys[left_name], collapsed_monkeys[right_name]} do
      {{:value, value}, {:entry, _entry}} ->
        {{:left, value}, right_name}

      {{:entry, _entry}, {:value, value}} ->
        {{:right, value}, left_name}

      {{:value, _left_value}, {:value, right_value}} when left_name == @human_branch_name ->
        {{:right, right_value}, :halt}

      {{:value, left_value}, {:value, _right_value}} when right_name == @human_branch_name ->
        {{:left, left_value}, :halt}
    end
    |> case do
      {{side, final_value}, :halt} ->
        solve_func = build_solve_operation_func(side, final_value, operation)
        [solve_func | stack]

      {{side, value}, next_cursor} ->
        solve_func = build_solve_operation_func(side, value, operation)
        next_stack = [solve_func | stack]
        build_solve_stack(collapsed_monkeys, next_cursor, next_stack)
    end
  end

  defp build_solve_operation_func(side, value, operation) do
    inverse_func =
      operation
      |> invert_operation()
      |> get_operation_func()

    case {side, invert_operation(operation)} do
      # Edge case - in all cases, except for (&1 + value), we can use `inverse_func`. However,
      # for this special case, the algebra dictates we must negate the input.
      {:left, :add} -> &inverse_func.(-&1, value)
      {:left, _} -> &inverse_func.(&1, value)
      {:right, _} -> &inverse_func.(&1, value)
    end
  end

  @spec parse_line!(String.t()) :: {String.t(), branch()}
  defp parse_line!(line) do
    [name, raw_entry] = String.split(line, ": ")
    {name, parse_branch!(raw_entry)}
  end

  @spec parse_entry!(String.t()) :: entry()
  defp parse_entry!(raw_entry) do
    [left, operation, right] = String.split(raw_entry, " ")

    %{
      left: left,
      operation: parse_operation!(operation),
      right: right
    }
  end

  @spec parse_branch!(String.t()) :: branch()
  defp parse_branch!(raw_branch) do
    case Integer.parse(raw_branch) do
      {value, ""} -> {:value, value}
      _ -> {:entry, parse_entry!(raw_branch)}
    end
  end

  @spec parse_operation!(String.t()) :: operation()
  defp parse_operation!("+"), do: :add
  defp parse_operation!("-"), do: :sub
  defp parse_operation!("*"), do: :mul
  defp parse_operation!("/"), do: :div
end
