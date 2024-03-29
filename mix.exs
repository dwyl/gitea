defmodule Gitea.MixProject do
  use Mix.Project

  @elixir_requirement "~> 1.9"

  def project do
    [
      app: :gitea,
      version: "1.1.11",
      elixir: @elixir_requirement,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        c: :test,
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      aliases: aliases(),
      deps: deps(),
      package: package(),
      description: "Simple Elixir interface with a Gitea (Git) Server"
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
      # Make HTTP Requests: github.com/edgurgel/httpoison
      {:httpoison, "~> 2.1.0"},

      # Parse JSON data: github.com/michalmuskala/jason
      {:jason, "~> 1.4.0"},

      # Check environment variables: github.com/dwyl/envar
      {:envar, "~> 1.1.0"},

      # Git interface: github.com/danhper/elixir-git-cli
      {:git_cli, "~> 0.3"},

      # Useful functions: github.com/dwyl/useful
      {:useful, "~> 1.10.0"},

      # Check test coverage: github.com/parroty/excoveralls
      {:excoveralls, "~> 0.15.0", only: :test},

      # Create Documentation for publishing Hex.docs:
      {:ex_doc, "~> 0.28", only: :dev},

      # Keep Code Tidy: https://github.com/rrrene/credo
      {:credo, "~> 1.6.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false}
    ]
  end

  defp aliases do
    [
      c: ["coveralls.html"]
    ]
  end

  defp package() do
    [
      files: ~w(lib LICENSE mix.exs README.md test-repo),
      name: "gitea",
      licenses: ["GPL-2.0-or-later"],
      maintainers: ["dwyl"],
      links: %{"GitHub" => "https://github.com/dwyl/gitea"}
    ]
  end
end
