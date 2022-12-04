defmodule AdventOfCode2022.Solution.Day2 do
  use AdventOfCode2022.Solution

  @type move :: :rock | :paper | :scissors
  @type outcome :: :win | :loss | :draw
  @draw_reward 3
  @win_reward 6

  @impl true
  @spec prepare_input(String.t()) :: [{String.t(), String.t()}]
  def prepare_input(filename) do
    File.read!(filename)
    |> String.trim_trailing()
    |> String.split("\n")
    |> Enum.map(&String.split(&1, " "))
  end

  @impl true
  @spec part1([{String.t(), String.t()}]) :: number()
  def part1(strategy_guide) do
    strategy_guide
    |> Enum.map(&parse_move_strategy_entry!/1)
    |> Enum.map(fn {opponent_move, our_move} ->
      score = move_score(our_move)
      reward = round_outcome(opponent_move, our_move) |> round_reward()
      score + reward
    end)
    |> Enum.sum()
  end

  @impl true
  @spec part2([{String.t(), String.t()}]) :: number()
  def part2(strategy_guide) do
    strategy_guide
    |> Enum.map(&parse_outcome_strategy_entry!/1)
    |> Enum.map(fn {opponent_move, outcome} ->
      score = move_for_outcome(opponent_move, outcome) |> move_score()
      reward = round_reward(outcome)
      score + reward
    end)
    |> Enum.sum()
  end

  @spec parse_move_strategy_entry!([String.t()]) :: {move(), move()}
  def parse_move_strategy_entry!([opponent_move, our_move]) do
    {
      parse_opponent_move!(opponent_move),
      parse_our_move!(our_move)
    }
  end

  @spec parse_outcome_strategy_entry!([String.t()]) :: {move(), outcome()}
  def parse_outcome_strategy_entry!([opponent_move, our_move]) do
    {
      parse_opponent_move!(opponent_move),
      parse_outcome!(our_move)
    }
  end

  @spec parse_opponent_move!(String.t()) :: move()
  defp parse_opponent_move!(move) do
    case move do
      "A" -> :rock
      "B" -> :paper
      "C" -> :scissors
    end
  end

  @spec parse_our_move!(String.t()) :: move()
  defp parse_our_move!(move) do
    case move do
      "X" -> :rock
      "Y" -> :paper
      "Z" -> :scissors
    end
  end

  @spec parse_outcome!(String.t()) :: outcome()
  defp parse_outcome!(move) do
    case move do
      "X" -> :loss
      "Y" -> :draw
      "Z" -> :win
    end
  end

  @spec move_score(move()) :: number()
  defp move_score(move) do
    case move do
      :rock -> 1
      :paper -> 2
      :scissors -> 3
    end
  end

  @spec round_outcome(move(), move()) :: outcome()
  defp round_outcome(opponent_move, our_move) when opponent_move == our_move do
    :draw
  end

  defp round_outcome(opponent_move, our_move) do
    case {opponent_move, our_move} do
      {:rock, :scissors} -> :loss
      {:rock, :paper} -> :win
      {:paper, :rock} -> :loss
      {:paper, :scissors} -> :win
      {:scissors, :paper} -> :loss
      {:scissors, :rock} -> :win
    end
  end

  @spec move_for_outcome(move(), outcome()) :: move()
  defp move_for_outcome(opponent_move, :draw) do
    opponent_move
  end

  defp move_for_outcome(opponent_move, :win) do
    case opponent_move do
      :rock -> :paper
      :scissors -> :rock
      :paper -> :scissors
    end
  end

  defp move_for_outcome(opponent_move, :loss) do
    case opponent_move do
      :rock -> :scissors
      :scissors -> :paper
      :paper -> :rock
    end
  end

  defp round_reward(outcome) do
    case outcome do
      :loss -> 0
      :draw -> @draw_reward
      :win -> @win_reward
    end
  end
end
