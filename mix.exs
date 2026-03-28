defmodule ElixirMite.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_mite,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {ElixirMite.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_ratatui, "~> 0.5"},
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:toml, "~> 0.7"},
      {:tzdata, "~> 1.1"}
    ]
  end
end
