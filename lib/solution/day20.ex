defmodule AdventOfCode2022.Solution.Day20 do
  require IEx

  alias AdventOfCode2022.Solution.Day20.RingBuffer
  use AdventOfCode2022.Solution

  @impl true
  def prepare_input(filename) do
    values =
      File.read!(filename)
      |> String.trim_trailing()
      |> String.split("\n")
      |> Enum.map(&String.to_integer/1)

    values
    |> RingBuffer.from_list()
  end

  @impl true
  def part1({buffer, refs}) do
    zero_ref = Enum.find(refs, fn ref -> RingBuffer.value(buffer, ref) == 0 end)
    mixed_buffer = mix_buffer(buffer, refs)

    [1000, 2000, 3000]
    |> Enum.map(fn coord ->
      RingBuffer.nth_after(mixed_buffer, zero_ref, coord)
    end)
    |> Enum.sum()
  end

  @spec mix_buffer(RingBuffer.t(), [reference()]) :: RingBuffer.t()
  defp mix_buffer(buffer, []) do
    buffer
  end

  defp mix_buffer(buffer, [next_ref | rest_refs]) do
    mix_value(buffer, next_ref)
    |> mix_buffer(rest_refs)
  end

  @spec mix_value(RingBuffer.t(), reference()) :: RingBuffer.t()
  defp mix_value(buffer, ref) do
    value = RingBuffer.value(buffer, ref)
    swap = swap_fn_for_value(value)

    1..abs(value)
    |> Enum.reduce(buffer, fn _, swapped_buffer ->
      swap.(swapped_buffer, ref)
    end)
  end

  @spec swap_fn_for_value(number()) :: (RingBuffer.t(), reference() -> RingBuffer.t())
  defp swap_fn_for_value(value) when value > 0 do
    &RingBuffer.swap_forward/2
  end

  defp swap_fn_for_value(value) when value < 0 do
    &RingBuffer.swap_backward/2
  end

  defp swap_fn_for_value(0) do
    fn buffer, _ref -> buffer end
  end

  defmodule RingBuffer do
    @enforce_keys :buffer
    defstruct [:buffer]

    @type link :: %{value: number(), next: reference(), previous: reference()}
    @type t :: %__MODULE__{buffer: %{reference() => link()}}

    @spec from_list([number()]) :: {__MODULE__.t(), [reference()]}
    def from_list(values) do
      ref_list =
        values
        |> Enum.map(&{make_ref(), %{value: &1}})

      {first_ref, _first_link} = Enum.at(ref_list, 0)
      {last_ref, _last_link} = Enum.at(ref_list, -1)

      refs = Enum.into(ref_list, %{})

      linked_refs =
        ref_list
        |> Enum.chunk_every(3, 1, :discard)
        |> Enum.reduce(refs, fn [{prev, _prev_link}, {current, _current_link}, {next, _next_lnk}],
                                acc_refs ->
          # Technically this has some redundant operations but by being overzealous we cover every
          # case except the first and last
          updated =
            acc_refs
            |> put_in([current, :previous], prev)
            |> put_in([current, :next], next)
            |> put_in([next, :previous], current)
            |> put_in([prev, :next], current)

          updated
        end)

      buffer =
        linked_refs
        |> Enum.into(%{})
        |> put_in([first_ref, :previous], last_ref)
        |> put_in([last_ref, :next], first_ref)

      {
        %__MODULE__{buffer: buffer},
        Enum.map(ref_list, fn {ref, _value} -> ref end)
      }
    end

    @spec value(__MODULE__.t(), reference()) :: number()
    def value(buffer, ref) do
      get_in(buffer.buffer, [ref, :value])
    end

    @spec swap_forward(__MODULE__.t(), reference()) :: __MODULE__.t()
    def swap_forward(buffer, ref) do
      %{previous: prev_ref, next: next_ref} = buffer.buffer[ref]
      %{next: after_next_ref} = buffer.buffer[next_ref]

      buffer
      |> Map.update!(:buffer, fn internal_buffer ->
        internal_buffer
        |> Map.update!(prev_ref, fn link -> %{link | next: next_ref} end)
        |> Map.update!(next_ref, fn link -> %{link | previous: prev_ref, next: ref} end)
        |> Map.update!(ref, fn link -> %{link | previous: next_ref, next: after_next_ref} end)
        |> Map.update!(after_next_ref, fn link -> %{link | previous: ref} end)
      end)
    end

    @spec swap_backward(__MODULE__.t(), reference()) :: __MODULE__.t()
    def swap_backward(buffer, ref) do
      %{previous: prev_ref, next: next_ref} = buffer.buffer[ref]
      %{previous: before_prev_ref} = buffer.buffer[prev_ref]

      buffer
      |> Map.update!(:buffer, fn internal_buffer ->
        internal_buffer
        |> Map.update!(next_ref, fn link -> %{link | previous: prev_ref} end)
        |> Map.update!(prev_ref, fn link -> %{link | previous: ref, next: next_ref} end)
        |> Map.update!(ref, fn link -> %{link | previous: before_prev_ref, next: prev_ref} end)
        |> Map.update!(before_prev_ref, fn link -> %{link | next: ref} end)
      end)
    end

    @spec nth_after(__MODULE__.t(), reference(), number()) :: number()
    def nth_after(buffer, ref, n) when is_map_key(buffer.buffer, ref) and n >= 0 do
      num_refs = map_size(buffer.buffer)

      selected_link =
        1..rem(n, num_refs)
        |> Enum.reduce(buffer.buffer[ref], fn _idx, cursor ->
          buffer.buffer[cursor.next]
        end)

      selected_link.value
    end
  end

  defimpl Enumerable, for: RingBuffer do
    def count(buffer) do
      {:ok, map_size(buffer.buffer)}
    end

    def member?(buffer, element) do
      buffer
      |> value_list()
      |> Enum.find(element)
    end

    def reduce(buffer, acc, fun) do
      buffer
      |> value_list()
      |> Enumerable.reduce(acc, fun)
    end

    def slice(_buffer) do
      {:error, __MODULE__}
    end

    defp value_list(buffer) when map_size(buffer.buffer) == 0 do
      []
    end

    defp value_list(buffer) do
      first_ref =
        buffer.buffer
        |> Map.keys()
        |> Enum.at(0)

      value_list(buffer, first_ref)
      |> Enum.reverse()
    end

    defp value_list(buffer, start_ref) do
      %{value: first_value, next: next_ref} = buffer.buffer[start_ref]
      value_list(buffer, start_ref, next_ref, [first_value])
    end

    defp value_list(_buffer, start_ref, cursor, acc) when start_ref == cursor do
      acc
    end

    defp value_list(buffer, start_ref, cursor, acc) do
      %{value: value, next: next_ref} = buffer.buffer[cursor]
      value_list(buffer, start_ref, next_ref, [value | acc])
    end
  end
end
