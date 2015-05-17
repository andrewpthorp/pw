defmodule PW.Mixfile do
  use Mix.Project

  def project do
    [app: :pw,
     version: "0.3.1",
     elixir: "~> 1.0",
     escript: escript_config,
     deps: deps]
  end

  def application do
    [applications: [:logger, :porcelain]]
  end

  defp deps do
    [{:porcelain, "~> 2.0.0"}]
  end

  defp escript_config do
    [main_module: PW.CLI]
  end
end
