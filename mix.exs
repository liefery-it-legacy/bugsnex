defmodule Bugsnex.Mixfile do
  use Mix.Project

  @version "0.4.3"
  def project do
    [
      app: :bugsnex,
      version: @version,
      elixir: "~> 1.4",
      description: "Elixir client for Bugsnag with helpers for Plug and Phoenix",
      docs: [source_ref: @version],
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {Bugsnex, []}, applications: [:logger, :httpoison, :poison, :plug]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/liefery/bugsnex"},
      maintainers: [
        "Manuel Kallenbach",
        "Tobias Pfeiffer",
        "Tiago Teixeira",
        "Daniel Schweighöfer"
      ]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.1"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "~> 1.5.0"},
      {:poison, ">= 1.5.0"},
      {:plug, "~> 1.6"},
      {:plug_cowboy, "~> 1.0", only: :test},
      {:phoenix, "~> 1.1", only: :test},
      {:bypass, "~> 0.5.1", only: :test},
      {:ex_doc, "~> 0.19", only: :dev},
      {:earmark, "~> 1.1", only: :dev}
    ]
  end
end
