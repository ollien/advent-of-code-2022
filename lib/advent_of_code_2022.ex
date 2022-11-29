defmodule AdventOfCode2022 do
  alias AdventOfCode2022.Solution

  @type part :: :part1 | :part2

  @spec get_day_module(non_neg_integer()) :: {:ok, module} | {:error, {:not_defined, String.t()}}
  def get_day_module(day_num) do
    module_name = get_day_module_name(day_num)

    res =
      try do
        module = String.to_existing_atom("Elixir.#{module_name}")

        {:ok, module}
      rescue
        ArgumentError -> {:error, {:not_defined, module_name}}
      end

    case res do
      {:ok, module} ->
        # Separated from the try to prevent rescuing something we didn't intend to
        warn_if_no_solution_impl(module)
        {:ok, module}

      other ->
        other
    end
  end

  @spec run_input_prep(module, String.t()) :: {:ok, any()} | {:error, :no_impl}
  def run_input_prep(module, filename) do
    :erlang.apply(module, :prepare_input, [filename])
    |> ensure_non_default_solution_output()
  end

  @spec run_part(module(), part, any()) ::
          {:ok, {part, any}} | {:error, {part, :no_impl}}
  def run_part(module, part, input) do
    part_func_name = get_part_func(part)

    part_output =
      :erlang.apply(module, part_func_name, [input])
      |> ensure_non_default_solution_output()

    case part_output do
      {:ok, output} -> {:ok, {part, output}}
      {:error, :no_impl} -> {:error, {part, :no_impl}}
    end
  end

  @spec print_part_report({:ok, {part, String.Chars.t()}} | {:error, {part, :no_impl}}) :: :ok
  def print_part_report({:ok, {part, output}}) do
    IO.puts("#{get_part_name(part)}: #{output}")
  end

  def print_part_report({:error, {part, :no_impl}}) do
    IO.puts("#{get_part_name(part)}: Not implemented!")
  end

  defp get_day_module_name(day_num) do
    "AdventOfCode2022.Solution.Day#{day_num}"
  end

  @spec warn_if_no_solution_impl(module()) :: :ok
  defp warn_if_no_solution_impl(module) do
    if not Solution.implemented_by?(module) do
      IO.warn("Module #{module} does not implement Solution behavior")
    end

    :ok
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

  @spec get_part_name(part) :: String.t()
  defp get_part_name(:part1) do
    "Part 1"
  end

  defp get_part_name(:part2) do
    "Part 2"
  end
end
