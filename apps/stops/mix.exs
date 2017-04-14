defmodule Stops.Mixfile do
  @moduledoc false
  use Mix.Project

  def project do
    [app: :stops,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :httpoison, :json_api, :repo_cache, :v3_api, :timex]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:httpoison, ">= 0.0.0"},
     {:v3_api, in_umbrella: true},
     {:json_api, in_umbrella: true},
     {:routes, in_umbrella: true},
     {:excoveralls, "~> 0.5", only: :test},
     {:repo_cache, in_umbrella: true},
     {:timex, ">= 0.0.0"},
     {:bypass, ">= 0.0.0", only: :test}
   ]
  end
end
