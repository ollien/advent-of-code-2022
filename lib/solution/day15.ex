defmodule AdventOfCode2022.Solution.Day15 do
  use AdventOfCode2022.Solution

  @type position :: {number(), number()}
  @type range :: {number(), number()}
  @type reading :: %{sensor: position(), beacon: position()}
  @scan_row 2_000_000

  @impl true
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map(&parse_line!/1)
  end

  @impl true
  @spec part1([reading]) :: number()
  def part1(readings) do
    scanned_ranges = scannable_beacons_in_row(readings)

    num_scanned_positions =
      scanned_ranges
      |> Enum.map(fn {range_start, range_end} -> abs(range_end - range_start) + 1 end)
      |> Enum.sum()

    beacons = readings |> Enum.map(fn %{beacon: beacon_pos} -> beacon_pos end)

    scanned_beacons = beacons_included_in_scan(scanned_ranges, beacons)
    num_scanned_positions - length(scanned_beacons)
  end

  @spec scannable_beacons_in_row([reading()]) :: [range()]
  defp scannable_beacons_in_row(readings) do
    scanned_ranges =
      readings
      |> Enum.map(fn %{sensor: sensor_pos, beacon: beacon_pos} ->
        distance = manhattan_distance(sensor_pos, beacon_pos)
        {sensor_pos, distance}
      end)
      |> Enum.map(fn {sensor_pos, radius} ->
        scannable_beacons_for_sensor(sensor_pos, radius, @scan_row)
      end)
      |> Enum.filter(&(&1 != nil))
      |> Enum.sort()

    scanned_ranges
    |> Enum.drop(1)
    |> Enum.reduce(
      [hd(scanned_ranges)],
      fn next_range, res = [last_range | rest_ranges] ->
        case merge_ranges(last_range, next_range) do
          [_range1, _range2] -> [next_range | res]
          [merged_range] -> [merged_range | rest_ranges]
        end
      end
    )
  end

  @spec manhattan_distance(position(), position()) :: number()
  defp manhattan_distance({x1, y1}, {x2, y2}) do
    abs(y2 - y1) + abs(x2 - x1)
  end

  @spec scannable_beacons_for_sensor(position(), number(), number()) :: range()
  defp scannable_beacons_for_sensor({sensor_x, sensor_y}, sensor_radius, row) do
    distance_to_row = abs(sensor_y - row)
    horizontal_scannable_distance = sensor_radius - distance_to_row

    if horizontal_scannable_distance > 0 do
      {
        sensor_x - horizontal_scannable_distance,
        sensor_x + horizontal_scannable_distance
      }
    else
      nil
    end
  end

  @spec beacons_included_in_scan([range()], [position()]) :: [position()]
  defp beacons_included_in_scan(scanned_ranges, beacon_positions) do
    beacon_positions
    |> Enum.filter(fn
      {_x, y} when y != @scan_row ->
        false

      {x, _y} ->
        included_range =
          Enum.find(scanned_ranges, fn {range_start, range_end} ->
            x >= range_start and x <= range_end
          end)

        included_range != nil
    end)
    |> Enum.uniq()
  end

  @spec merge_ranges(range(), range()) :: [range()]
  defp merge_ranges(range1 = {start1, _end1}, range2 = {start2, _end2}) when start1 > start2 do
    merge_ranges(range2, range1)
  end

  defp merge_ranges(range1 = {start1, end1}, {start2, end2})
       when start2 >= start1 and end2 <= end1 do
    [range1]
  end

  defp merge_ranges(range1 = {start1, end1}, range2 = {start2, end2}) do
    if Range.disjoint?(start1..end1, start2..end2) do
      [range1, range2]
    else
      [{start1, end2}]
    end
  end

  @spec parse_line!(String.t()) :: reading()
  defp parse_line!(line) do
    pattern = ~r/Sensor at x=(-?\d+), y=(-?\d+): closest beacon is at x=(-?\d+), y=(-?\d+)/
    [_match, sensor_x, sensor_y, beacon_x, beacon_y] = Regex.run(pattern, line)

    sensor_pos = {
      sensor_x |> String.to_integer(),
      sensor_y |> String.to_integer()
    }

    beacon_pos = {
      beacon_x |> String.to_integer(),
      beacon_y |> String.to_integer()
    }

    %{sensor: sensor_pos, beacon: beacon_pos}
  end
end
