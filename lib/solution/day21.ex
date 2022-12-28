defmodule AdventOfCode2022.Solution.Day21 do
  use AdventOfCode2022.Solution

  @type operation :: :add | :sub | :mul | :div
  @type branch :: {:entry, entry()} | {:value, number()}
  @type entry :: %{left: String.t(), operation: operation(), right: String.t()}
  @type monkeys :: %{String.t() => branch()}

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
    evaluate_monkey(monkeys, "root")
  end

  @spec evaluate_monkey(monkeys(), String.t()) :: number()
  defp evaluate_monkey(monkeys, name) do
    case monkeys[name] do
      {:value, value} -> value
      {:entry, entry} -> evaluate_entry(monkeys, entry)
    end
  end

  @spec evaluate_monkey(monkeys(), entry()) :: number()
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
  defp get_operation_func(:div), do: &Kernel.div/2

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
