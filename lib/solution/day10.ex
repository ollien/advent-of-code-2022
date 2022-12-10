defmodule AdventOfCode2022.Solution.Day10 do
  use AdventOfCode2022.Solution

  @type instruction :: :noop | {:addx, number()}
  @crt_width 40

  @impl true
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map(&parse_instruction!/1)
  end

  @spec parse_instruction!(String.t()) :: instruction()
  defp parse_instruction!(line) do
    case String.split(line, " ") do
      ["noop"] -> :noop
      ["addx", value] -> {:addx, String.to_integer(value)}
    end
  end

  @impl true
  @spec part1([instruction]) :: number()
  def part1(instructions) do
    register_log = run_instructions(instructions)
    accumulate_signal_strengths(register_log)
  end

  @impl true
  @spec part2([instruction]) :: String.t()
  def part2(instructions) do
    register_log = run_instructions(instructions)

    output =
      register_log
      |> Enum.with_index()
      |> Enum.reduce("", fn {register_value, cycle}, output ->
        next_char = get_cycle_display_output(register_value, cycle)

        output <> next_char
      end)

    "\n#{output}"
  end

  # Run the instructions, return the value of the register at every clock cycle
  @spec run_instructions([instruction]) :: [number()]
  defp run_instructions(instructions) do
    {register_log, _register_value} =
      Enum.reduce(instructions, {[], 1}, fn instruction, {register_log, register_value} ->
        {new_log_entries, next_register_value} = run_instruction(instruction, register_value)
        {new_log_entries ++ register_log, next_register_value}
      end)

    Enum.reverse(register_log)
  end

  @spec run_instruction(instruction(), number()) :: {[number()], number()}
  def run_instruction(:noop, register) do
    {[register], register}
  end

  def run_instruction({:addx, value}, register) do
    {[register, register], register + value}
  end

  @spec accumulate_signal_strengths([number()]) :: number()
  defp accumulate_signal_strengths(register_log) do
    # By dropping the first 19 elements, the first element of this list will be the 40th
    [initial_signal_register | rest_register_log] = Enum.drop(register_log, 19)
    accumulate_signal_strengths(rest_register_log, 20, initial_signal_register * 20)
  end

  defp accumulate_signal_strengths(register_log, idx, total) do
    # By dropping the first 39 elements, the first element of this list will be the 40th
    case Enum.drop(register_log, 39) do
      [] ->
        total

      [signal_register | rest_register_log] ->
        accumulate_signal_strengths(
          rest_register_log,
          idx + 40,
          total + signal_register * (idx + 40)
        )
    end
  end

  @spec get_cycle_display_output(number(), number()) :: String.t()
  defp get_cycle_display_output(register_value, cycle)
       when register_value - 1 == rem(cycle, @crt_width) or
              register_value == rem(cycle, @crt_width) or
              register_value + 1 == rem(cycle, @crt_width) do
    "#" <> get_display_char_suffix(cycle)
  end

  defp get_cycle_display_output(_register_value, cycle) do
    "." <> get_display_char_suffix(cycle)
  end

  @spec get_display_char_suffix(number()) :: String.t()
  defp get_display_char_suffix(cycle) when rem(cycle + 1, @crt_width) == 0 do
    # Only _AFTER_ the 40th cycle do we wrap
    "\n"
  end

  defp get_display_char_suffix(_cycle) do
    ""
  end
end
