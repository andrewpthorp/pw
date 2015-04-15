defmodule PW.Mixfile do
  use Mix.Project

  def project do
    [app: :pw,
     version: "0.0.1",
     elixir: "~> 1.0",
     escript: escript_config,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :porcelain]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:porcelain, "~> 2.0.0"},
     {:mock, "~> 0.1.0", only: :test}]
  end

  defp escript_config do
    [main_module: PW.CLI]
  end
end
