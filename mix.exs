defmodule Gitea.MixProject do
  use Mix.Project

  def project do
    [
      app: :gitea,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir interface for Gitea server",
      package: package()
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
    [{:git_cli, "~> 0.3.0"}]
  end

  defp package() do
    [
      files: ~w(lib LICENSE mix.exs README.md),
      name: "gitea",
      licenses: ["GPL-2.0-or-later"],
      maintainers: ["dwyl"],
      links: %{"GitHub" => "https://github.com/dwyl/gitea"}
    ]
  end
end
