defmodule AdventOfCode2022.CLI do
  def main(args \\ []) do
    get_action(args) |> run()
  end

  defp get_action([raw_day_num, filename]) do
    case Integer.parse(raw_day_num) do
      {day_num, ""} when day_num > 0 ->
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
    case AdventOfCode2022.get_day_module(day_num) do
      {:ok, module} ->
        input =
          AdventOfCode2022.run_input_prep(module, filename)
          |> unwrap_prepared_input(filename)

        AdventOfCode2022.run_part(module, :part1, input)
        |> AdventOfCode2022.print_part_report()

        AdventOfCode2022.run_part(module, :part2, input)
        |> AdventOfCode2022.print_part_report()

      {:error, {:not_defined, module_name}} ->
        IO.puts(:stderr, "No solution found for module #{module_name}")
    end

    :ok
  end

  defp unwrap_prepared_input({:ok, prepared_input}, _default) do
    prepared_input
  end

  defp unwrap_prepared_input({:error, :no_impl}, default) do
    default
  end
end
