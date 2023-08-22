defmodule DafarmzBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :dafarmz_bot,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ex_rated],
      mod: {DafarmzBot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, "~> 0.8"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:nodejs, "~> 2.0"},
      {:number, "~> 1.0"},
      {:timex, "~> 3.0"},
      {:ex_rated, "~> 2.0"}
    ]
  end
end
