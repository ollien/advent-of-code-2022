defmodule AdventOfCode2022.CLI do
  alias AdventOfCode2022.Solution

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

  @spec run(:help) :: :ok
  defp run(:help) do
    IO.puts("Usage: #{:escript.script_name()} day_num input_file")
    :ok
  end

  @spec run({:run_day, %{day: non_neg_integer(), filename: String.t()}}) :: :ok
  defp run({:run_day, %{day: day_num, filename: filename}}) do
    case get_day_module(day_num) do
      {:ok, module} ->
        warn_if_no_solution_impl(module)

        input =
          run_input_prep(module, filename)
          |> unwrap_prepared_input(filename)

        run_part(module, :part1, input) |> print_part_report()
        run_part(module, :part2, input) |> print_part_report()

      {:error, {:not_defined, module_name}} ->
        IO.puts(:stderr, "No solution found for module #{module_name}")
    end

    :ok
  end

  @spec warn_if_no_solution_impl(module()) :: :ok
  defp warn_if_no_solution_impl(module) do
    if not Solution.implemented_by?(module) do
      IO.warn("Module #{module} does not implement Solution behavior")
    end

    :ok
  end

  @spec get_day_module(non_neg_integer()) :: {:ok, module} | {:error, {:not_defined, String.t()}}
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

  @spec run_input_prep(module, String.t()) :: {:ok, any()} | {:error, :no_impl}
  defp run_input_prep(module, filename) do
    :erlang.apply(module, :prepare_input, [filename])
    |> ensure_non_default_solution_output()
  end

  defp unwrap_prepared_input({:ok, prepared_input}, _default) do
    prepared_input
  end

  defp unwrap_prepared_input({:error, :no_impl}, default) do
    default
  end

  @spec run_part(module(), part, any()) ::
          {:ok, {part, any}} | {:error, {part, :no_impl}}
  defp run_part(module, part, input) do
    part_func_name = get_part_func(part)

    part_output =
      :erlang.apply(module, part_func_name, [input])
      |> ensure_non_default_solution_output()

    case part_output do
      {:ok, output} -> {:ok, {part, output}}
      {:error, :no_impl} -> {:error, {part, :no_impl}}
    end
  end

  @spec get_part_func(part) :: atom
  defp get_part_func(:part1) do
    :part1
  end

  defp get_part_func(:part2) do
    :part2
  end

  defp ensure_non_default_solution_output(:no_impl) do
    {:error, :no_impl}
  end

  defp ensure_non_default_solution_output(output) do
    {:ok, output}
  end

  @spec print_part_report({:ok, {part, String.Chars.t()}} | {:error, {part, :no_impl}}) :: :ok
  defp print_part_report({:ok, {part, output}}) do
    IO.puts("#{get_part_name(part)}: #{output}")
  end

  defp print_part_report({:error, {part, :no_impl}}) do
    IO.puts("#{get_part_name(part)}: Not implemented!")
  end

  @spec get_part_name(part) :: String.t()
  defp get_part_name(:part1) do
    "Part 1"
  end

  defp get_part_name(:part2) do
    "Part 2"
  end
end
