defmodule Bench.MixProject do
  use Mix.Project

  def project do
    [
      app: :bench,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases() do
    [
      "bench.xml_to_map": ["run xml_to_map.exs"]
    ]
  end

  defp deps do
    [
      {:benchee, "~> 1.0", only: :dev, runtime: false},
      {:crockford_base32, path: "../", override: true},
      {:base32_crockford, "~> 1.0", only: :dev},
      {:base32, "~> 2021.3", hex: :base32_clockwork, only: :dev}
    ]
  end
end
