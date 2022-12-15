defmodule AdventOfCode2022.Solution.Day15 do
  use AdventOfCode2022.Solution

  @type position :: {number(), number()}
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
  def part1(readings) do
    get_scannable_positions_without_beacon(readings)
    |> Enum.count()
  end

  defp get_scannable_positions_without_beacon(readings) do
    beacon_positions =
      readings
      |> Enum.map(fn %{beacon: beacon_pos} -> beacon_pos end)
      |> Enum.into(MapSet.new())

    readings
    |> Enum.map(fn %{sensor: sensor_pos, beacon: beacon_pos} ->
      distance = manhattan_distance(sensor_pos, beacon_pos)
      {sensor_pos, distance}
    end)
    # This is super inefficient but I'm too lazy to do range subtraction or anything like that
    |> Enum.flat_map(fn {sensor_pos, radius} ->
      get_scannable_positions_in_row(sensor_pos, radius, @scan_row)
    end)
    |> Enum.into(MapSet.new())
    |> MapSet.difference(beacon_positions)
  end

  @spec manhattan_distance(position(), position()) :: number()
  defp manhattan_distance({x1, y1}, {x2, y2}) do
    abs(y2 - y1) + abs(x2 - x1)
  end

  @spec get_scannable_positions_in_row(position(), number(), number()) :: [position()]
  defp get_scannable_positions_in_row({sensor_x, sensor_y}, sensor_radius, row) do
    distance_to_row = abs(sensor_y - row)
    horizontal_scannable_distance = sensor_radius - distance_to_row

    if horizontal_scannable_distance > 0 do
      (sensor_x - horizontal_scannable_distance)..(sensor_x + horizontal_scannable_distance)
      |> Enum.map(&{&1, row})
    else
      []
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
