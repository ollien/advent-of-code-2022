defmodule AdventOfCode2022.Solution.Day7 do
  use AdventOfCode2022.Solution

  @type input_line :: command() | fs_entry()

  @type command ::
          {:command, :ls}
          | {:command, :cd, :up}
          | {:command, :cd, :root}
          | {:command, :cd, String.t()}

  @type fs_entry() :: {:dir, String.t()} | {:file, String.t(), number()}
  @type filesystem :: %{String.t() => filesystem() | {:file, number()}}

  @impl true
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map(&parse_line!/1)
    |> build_tree()
  end

  @impl true
  @spec part1(filesystem()) :: number()
  def part1(filesystem) do
    get_dirs(filesystem)
    |> Enum.map(fn path ->
      get_in(filesystem, path)
      |> get_fs_size()
    end)
    |> Enum.filter(&(&1 < 100_000))
    |> Enum.sum()
  end

  @impl true
  @spec part2(filesystem()) :: number()
  def part2(filesystem) do
    space_free = 70_000_000 - get_fs_size(filesystem)

    get_dirs(filesystem)
    |> Enum.map(fn path ->
      get_in(filesystem, path)
      |> get_fs_size()
    end)
    |> Enum.filter(&(space_free + &1 > 30_000_000))
    |> Enum.min()
  end

  @spec get_dirs(filesystem) :: [[String.t()]]
  defp get_dirs(filesystem) do
    get_dirs(filesystem, ["/"], [])
  end

  defp get_dirs({:file, _}, _, dirs) do
    dirs
  end

  defp get_dirs(filesystem, cursor, dirs) do
    # i feel like there has to be a better way to write this...
    contents =
      filesystem
      |> get_in(cursor)
      |> Enum.reduce(dirs, fn
        {_name, {:file, _}}, acc ->
          acc

        {name, %{}}, acc ->
          next_cursor = cursor ++ [name]
          get_dirs(filesystem, next_cursor, acc)
      end)

    [cursor | contents]
  end

  defp get_fs_size({:file, size}) do
    size
  end

  defp get_fs_size(filesystem) do
    filesystem
    |> Enum.map(fn {_, entry} -> get_fs_size(entry) end)
    |> Enum.sum()
  end

  defp parse_line!(line) do
    parsers = [
      &parse_command/1,
      &parse_dir/1,
      &parse_file/1
    ]

    parsed =
      Enum.find_value(
        parsers,
        fn parser ->
          case parser.(line) do
            {:ok, parsed} -> parsed
            {:error, :no_match} -> nil
          end
        end
      )

    if parsed == nil do
      raise ~s(Invalid line "#{line}")
    else
      parsed
    end
  end

  @spec parse_command(String.t()) :: {:ok, command()} | {:error, :no_match}
  def parse_command(line) do
    pattern = ~r/^\$ (ls|cd (.+))/

    case Regex.run(pattern, line) do
      [_match, "ls"] -> {:ok, {:command, :ls}}
      [_match, _cd, "/"] -> {:ok, {:command, :cd, :root}}
      [_match, _cd, ".."] -> {:ok, {:command, :cd, :up}}
      [_match, _cd, dir_name] -> {:ok, {:command, :cd, dir_name}}
      nil -> {:error, :no_match}
    end
  end

  @spec parse_dir(String.t()) :: {:ok, {:dir, String.t()}} | {:error, :no_match}
  def parse_dir(line) do
    pattern = ~r/^dir (.+)/

    case Regex.run(pattern, line) do
      [_match, name] -> {:ok, {:dir, name}}
      nil -> {:error, :no_match}
    end
  end

  @spec parse_file(String.t()) :: {:ok, {:file, String.t(), number()}} | {:error, :no_match}
  def parse_file(line) do
    pattern = ~r/^(\d+) (.+)/

    case Regex.run(pattern, line) do
      [_match, size, name] -> {:ok, {:file, name, String.to_integer(size)}}
      nil -> {:error, :no_match}
    end
  end

  @spec build_tree([input_line()]) :: filesystem()
  defp build_tree([first_input_line | rest_lines]) do
    # This isn't specified in the puzzle, but I'm fairly certain that since there's no default PWD
    # we ** HAVE** to start by cd'ing to the root
    {:command, :cd, :root} = first_input_line
    build_tree(rest_lines, ["/"], %{"/" => %{}})
  end

  @spec build_tree([input_line()], [String.t()], filesystem()) :: filesystem()
  defp build_tree([], _, filesystem) do
    filesystem
  end

  defp build_tree([input_line | rest_lines], path, filesystem) do
    pwd = get_in(filesystem, path)

    case input_line do
      {:command, :ls} ->
        {dir_entries, after_ls_lines} = get_entries_after_ls(rest_lines)

        updated_pwd =
          Enum.map(dir_entries, fn
            {:dir, name} -> {name, %{}}
            {:file, name, size} -> {name, {:file, size}}
          end)
          |> Enum.into(pwd)

        updated_filesystem = put_in(filesystem, path, updated_pwd)
        build_tree(after_ls_lines, path, updated_filesystem)

      {:command, :cd, :up} ->
        build_tree(rest_lines, Enum.drop(path, -1), filesystem)

      {:command, :cd, :root} ->
        build_tree(rest_lines, ["/"], filesystem)

      {:command, :cd, name} ->
        build_tree(rest_lines, path ++ [name], filesystem)
    end
  end

  @spec get_entries_after_ls([input_line()]) :: {[fs_entry()] | [input_line()]}
  defp get_entries_after_ls(input_lines) do
    input_lines
    |> Enum.split_while(fn
      {:file, _, _} -> true
      {:dir, _} -> true
      _ -> false
    end)
  end
end
