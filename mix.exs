defmodule AdventOfCode2022.MixProject do
  use Mix.Project

  def project do
    [
      app: :advent_of_code_2022,
      version: "0.1.0",
      elixir: "~> 1.14",
      deps: deps(),
      escript: escript()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 1.2"}
    ]
  end

  defp escript do
    [main_module: AdventOfCode2022.CLI]
  end
end
