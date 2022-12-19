defmodule AdventOfCode2022.Solution.Day18 do
  use AdventOfCode2022.Solution

  @type position :: {number(), number(), number()}
  @type range_tuple :: {number(), number()}

  @impl true
  @spec prepare_input(String.t()) :: [position()]
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map(&parse_line!/1)
    |> Enum.into(MapSet.new())
  end

  @impl true
  @spec part1(MapSet.t(position())) :: number()
  def part1(cubes) do
    cubes
    |> Enum.flat_map(fn cube ->
      neighbors(cube)
      |> Enum.reject(&MapSet.member?(cubes, &1))
    end)
    |> Enum.count()
  end

  @impl true
  @spec part2(MapSet.t(position())) :: number()
  def part2(cubes) do
    {x_min, x_max} =
      cubes
      |> Enum.map(fn {x, _y, _z} -> x end)
      |> Enum.min_max()

    {y_min, y_max} =
      cubes
      |> Enum.map(fn {_x, y, _z} -> y end)
      |> Enum.min_max()

    {z_min, z_max} =
      cubes
      |> Enum.map(fn {_x, _y, z} -> z end)
      |> Enum.min_max()

    # Scan *around* the ball
    exterior_scan({x_min - 1, x_max + 1}, {y_min - 1, y_max + 1}, {z_min - 1, z_max + 1}, cubes)
  end

  @spec exterior_scan(range_tuple(), range_tuple(), range_tuple(), MapSet.t(position())) ::
          number()
  defp exterior_scan(
         x_range = {x_min, _x_max},
         y_range = {y_min, _y_max},
         z_range = {z_min, _z_max},
         cubes
       ) do
    exterior_scan([{x_min, y_min, z_min}], MapSet.new(), 0, x_range, y_range, z_range, cubes)
  end

  @spec exterior_scan(
          [position()],
          MapSet.t(position()),
          number(),
          range_tuple(),
          range_tuple(),
          range_tuple(),
          MapSet.t(position())
        ) ::
          number()
  defp exterior_scan([], _visited, cubes_encountered, _x_range, _y_range, _z_range, _cubes) do
    cubes_encountered
  end

  defp exterior_scan(
         full_to_visit = [cursor | to_visit],
         visited,
         total_cubes_encountered,
         x_range,
         y_range,
         z_range,
         cubes
       ) do
    if MapSet.member?(visited, cursor) do
      exterior_scan(
        to_visit,
        visited,
        total_cubes_encountered,
        x_range,
        y_range,
        z_range,
        cubes
      )
    else
      continue_exterior_scan(
        full_to_visit,
        visited,
        total_cubes_encountered,
        x_range,
        y_range,
        z_range,
        cubes
      )
    end
  end

  @spec continue_exterior_scan(
          [position()],
          MapSet.t(position()),
          number(),
          range_tuple(),
          range_tuple(),
          range_tuple(),
          MapSet.t(position())
        ) ::
          number()
  defp continue_exterior_scan(
         [cursor | to_visit],
         visited,
         cubes_encountered,
         x_range = {x_min, x_max},
         y_range = {y_min, y_max},
         z_range = {z_min, z_max},
         cubes
       ) do
    visitable_neighbors =
      neighbors(cursor)
      |> Enum.reject(&MapSet.member?(visited, &1))
      |> Enum.filter(fn {x, y, z} ->
        x >= x_min and x <= x_max and y >= y_min and y <= y_max and z >= z_min and z <= z_max
      end)

    # Count every time we hit a cube - we can only hit a cube's side once, but we can hit a cube
    # up to six times
    local_cubes_encountered =
      visitable_neighbors
      |> Enum.filter(&MapSet.member?(cubes, &1))
      |> Enum.count()

    non_cube_neighbors =
      visitable_neighbors
      |> Enum.reject(&MapSet.member?(cubes, &1))

    next_cubes_encountered = local_cubes_encountered + cubes_encountered
    next_to_visit = non_cube_neighbors ++ to_visit
    next_visited = MapSet.put(visited, cursor)

    exterior_scan(
      next_to_visit,
      next_visited,
      next_cubes_encountered,
      x_range,
      y_range,
      z_range,
      cubes
    )
  end

  @spec neighbors(position()) :: [position()]
  defp neighbors({x, y, z}) do
    [
      {x - 1, y, z},
      {x + 1, y, z},
      {x, y - 1, z},
      {x, y + 1, z},
      {x, y, z - 1},
      {x, y, z + 1}
    ]
  end

  @spec parse_line!(String.t()) :: position()
  defp parse_line!(line) do
    [x, y, z] = String.split(line, ",")

    {
      x |> String.to_integer(),
      y |> String.to_integer(),
      z |> String.to_integer()
    }
  end
end
