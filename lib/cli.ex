defmodule AdventOfCode2022.CLI do
  require IEx
  @type part :: :part1 | :part2

  def main(args \\ []) do
    get_action(args) |> run()
  end

  defp get_action([raw_day_num, filename]) do
    case Integer.parse(raw_day_num) do
      {day_num, ""} when raw_day_num >= 0 ->
        {:run_day, %{day: day_num, filename: filename}}

      {_arg, _extra} ->
        :help

      :error ->
        :help
    end
  end

  defp get_action(_args) do
    :help
  end

  defp run(:help) do
    IO.puts("Usage: #{:escript.script_name()} day_num input_file")
  end

  defp run({:run_day, %{day: day_num, filename: filename}}) do
    case get_day_module(day_num) do
      {:ok, module} ->
        # We should have already made sure this module existed, so we will throw if it fails
        Code.ensure_loaded!(module)

        input =
          case run_input_prep(module, filename) do
            {:ok, prepped_input} -> prepped_input
            {:error, :not_defined} -> filename
          end

        run_part(module, :part1, input) |> print_part_report()
        run_part(module, :part2, input) |> print_part_report()

      {:error, {:not_defined, module_name}} ->
        IO.puts(:stderr, "No solution found for module #{module_name}")
    end
  end

  defp get_day_module(day_num) do
    module_name = get_day_module_name(day_num)

    try do
      module = String.to_existing_atom("Elixir.#{module_name}")
      {:ok, module}
    rescue
      ArgumentError -> {:error, {:not_defined, module_name}}
    end
  end

  defp get_day_module_name(day_num) do
    "AdventOfCode2022.Solution.Day#{day_num}"
  end

  defp run_input_prep(module, filename) do
    if Kernel.function_exported?(module, :prepare_input, 1) do
      {:ok, :erlang.apply(module, :prepare_input, [filename])}
    else
      {:error, :not_defined}
    end
  end

  @spec run_part(module(), part, String.t()) ::
          {:ok, {part, any}} | {:error, {part, :not_defined}}
  defp run_part(module, part, input) do
    part_func_name = get_part_func(part)

    if Kernel.function_exported?(module, part_func_name, 1) do
      {:ok, {part, :erlang.apply(module, part_func_name, [input])}}
    else
      {:error, {part, :not_defined}}
    end
  end

  defp get_part_func(:part1) do
    :part1
  end

  defp get_part_func(:part2) do
    :part2
  end

  defp print_part_report({:ok, {part, output}}) do
    IO.puts("#{get_part_name(part)}: #{output}")
  end

  defp print_part_report({:error, {part, :not_defined}}) do
    IO.puts("#{get_part_name(part)}: Not implemented!")
  end

  defp get_part_name(:part1) do
    "Part 1"
  end

  defp get_part_name(:part2) do
    "Part 2"
  end
end
