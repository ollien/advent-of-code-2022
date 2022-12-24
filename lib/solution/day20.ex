defmodule AdventOfCode2022.Solution.Day20 do
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

    mix_buffer(buffer, refs)
    |> sum_grove_coordinates(zero_ref)
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
  def mix_value(buffer, ref) do
    value = RingBuffer.value(buffer, ref)

    num_to_traverse =
      cond do
        # We must travel an extra step if we are going past the original
        value > 0 and abs(value) >= Enum.count(buffer) -> value + 1
        value < 0 and abs(value) >= Enum.count(buffer) -> value - 2
        # If we are negative (here and above), we must go an extra step since we get the element "after"
        value < 0 -> value - 1
        true -> value
      end

    ref_to_move_to = RingBuffer.nth_after(buffer, ref, num_to_traverse)
    RingBuffer.move_after(buffer, ref_to_move_to, ref)
  end

  @spec sum_grove_coordinates(RingBuffer.t(), reference()) :: number()
  defp sum_grove_coordinates(buffer, start_point) do
    [1000, 2000, 3000]
    |> Enum.map(fn coord ->
      ref = RingBuffer.nth_after(buffer, start_point, coord)
      RingBuffer.value(buffer, ref)
    end)
    |> Enum.sum()
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

    @spec to_list(__MODULE__.t(), reference()) :: [number()]
    def to_list(buffer, start_ref) do
      %{value: first_value, next: next_ref} = buffer.buffer[start_ref]
      to_list(buffer, start_ref, next_ref, [first_value])
    end

    @spec to_list(__MODULE__.t(), reference(), reference(), [number()]) :: [number()]
    defp to_list(_buffer, start_ref, cursor, acc) when start_ref == cursor do
      acc
      |> Enum.reverse()
    end

    defp to_list(buffer, start_ref, cursor, acc) do
      %{value: value, next: next_ref} = buffer.buffer[cursor]
      to_list(buffer, start_ref, next_ref, [value | acc])
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

    @spec move_after(__MODULE__.t(), reference(), reference()) :: __MODULE__.t()
    def move_after(buffer, relative_ref, ref)
        when is_map_key(buffer.buffer, relative_ref) and is_map_key(buffer.buffer, ref) do
      if relative_ref == ref || buffer.buffer[relative_ref].next == ref do
        buffer
      else
        do_move_after(buffer, relative_ref, ref)
      end
    end

    @spec do_move_after(__MODULE__.t(), reference(), reference()) :: __MODULE__.t()
    defp do_move_after(buffer, relative_ref, ref) do
      %{next: next_ref} = buffer.buffer[relative_ref]

      buffer
      |> splice(ref)
      |> Map.update!(:buffer, fn internal_buffer ->
        internal_buffer
        |> Map.update!(relative_ref, fn link -> %{link | next: ref} end)
        |> Map.update!(ref, fn link -> %{link | previous: relative_ref, next: next_ref} end)
        |> Map.update!(next_ref, fn link -> %{link | previous: ref} end)
      end)
    end

    @spec splice(__MODULE__.t(), reference()) :: __MODULE__.t()
    defp splice(buffer, ref) when is_map_key(buffer.buffer, ref) do
      %{previous: prev_ref, next: next_ref} = buffer.buffer[ref]

      buffer
      |> Map.update!(:buffer, fn internal_buffer ->
        internal_buffer
        |> Map.update!(prev_ref, fn link -> %{link | next: next_ref} end)
        |> Map.update!(next_ref, fn link -> %{link | previous: prev_ref} end)
      end)
    end

    @spec nth_after(__MODULE__.t(), reference(), number()) :: reference()
    def nth_after(buffer, ref, 0) when is_map_key(buffer.buffer, ref) do
      ref
    end

    def nth_after(buffer, ref, n) when is_map_key(buffer.buffer, ref) do
      num_refs = map_size(buffer.buffer)
      traverse = traversal_fn(n)

      {end_ref, _end_link} =
        traversal_range(n, num_refs)
        |> Enum.reduce({ref, buffer.buffer[ref]}, fn _idx, {_cursor_ref, cursor} ->
          traversed_ref = traverse.(cursor)

          traversed_ref =
            if traversed_ref == ref do
              traverse.(buffer.buffer[traversed_ref])
            else
              traversed_ref
            end

          {traversed_ref, buffer.buffer[traversed_ref]}
        end)

      end_ref
    end

    @spec traversal_fn(number()) :: (link() -> link())
    defp traversal_fn(value) when value > 0 do
      fn cursor -> cursor.next end
    end

    defp traversal_fn(value) when value < 0 do
      fn cursor -> cursor.previous end
    end

    @spec traversal_range(number(), number()) :: Enum.t(number())
    defp traversal_range(n, max) do
      range_end = abs(rem(n, max))

      if range_end == 0 do
        # closest we can get to an empty range
        []
      else
        1..range_end
      end
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

      RingBuffer.to_list(buffer, first_ref)
      |> Enum.reverse()
    end
  end
end
