defmodule CrockfordBase32.MixProject do
  use Mix.Project

  @source_url "https://github.com/xinz/crockford_base32"

  def project do
    [
      app: :crockford_base32,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs()
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
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:benchee, "~> 1.0", only: :dev},
      {:base32_crockford, "~> 1.0", only: :dev},
      {:base32, "~> 2021.3", hex: :base32_clockwork, only: :dev}
    ]
  end

  defp description do
    "An Elixir Implementation of Douglas Crockford's Base32 encode and decode."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Xin Zou"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      formatter_opts: [gfm: true],
      extras: [
        "README.md"
      ]
    ]
  end
end
