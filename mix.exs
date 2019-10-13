defmodule Ops.MixProject do
  use Mix.Project

  def project do
    [
      app: :ops,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:timex, "~> 3.6.1"},
      {:jason, "~> 1.0"},
      {:sdk, git: "https://github.com/outcastby/sdk.git"},
      {:mock, "0.3.3", only: :test}
    ]
  end
end
