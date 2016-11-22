defmodule DotCom.Mixfile do
  use Mix.Project

  def project do
    [apps_path: "apps",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     preferred_cli_env: [coveralls: :test, "coveralls.json": :test],
     test_coverage: [tool: ExCoveralls],
     dialyzer: [
       plt_add_apps: [:mix, :porcelain, :phoenix_live_reload]],
     deps: deps]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options.
  #
  # Dependencies listed here are available only for this project
  # and cannot be accessed from applications inside the apps folder
  defp deps do
    [{:credo, ">= 0.0.0", only: [:dev, :test]},
     {:excoveralls, "~> 0.5", only: :test}]
  end

end
