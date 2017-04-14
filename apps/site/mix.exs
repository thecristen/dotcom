defmodule Site.Mixfile do
  use Mix.Project

  def project do
    [app: :site,
     version: "0.0.1",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    apps = [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext,
            :stops, :routes, :alerts, :news, :schedules, :predictions, :timex,
            :inflex, :html_sanitize_ex, :logger_logentries_backend,
            :logster, :sizeable, :feedback, :zones, :fares, :content, :holiday,
            :parallel_stream, :vehicles, :tzdata, :google_maps, :system_metrics, :floki]

    apps = if Mix.env == :prod do
      [:ehmon | apps]
    else
      apps
    end

    [mod: {Site, []},
     included_applications: [:laboratory],
     applications: apps
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.2"},
     {:phoenix_pubsub, "~> 1.0"},
     {:phoenix_html, "~> 2.6"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.9"},
     {:cowboy, "~> 1.0"},
     {:tzdata, github: "paulswartz/tzdata", override: true},
     {:timex, ">= 2.0.0"},
     {:stops, in_umbrella: true},
     {:routes, in_umbrella: true},
     {:alerts, in_umbrella: true},
     {:holiday, in_umbrella: true},
     {:news, in_umbrella: true},
     {:schedules, in_umbrella: true},
     {:ehmon, git: "https://github.com/heroku/ehmon.git", tag: "v4", only: :prod},
     {:predictions, in_umbrella: true},
     {:exrm, ">= 0.0.0", only: :prod},
     {:inflex, "~> 1.8.0"},
     {:html_sanitize_ex, "~> 1.1.0"},
     {:logster, "~> 0.4.0"},
     {:logger_logentries_backend, github: "paulswartz/logger_logentries_backend"},
     {:excheck, "~> 0.5", only: :test},
     {:triq, github: "triqng/triq", only: :test},
     {:sizeable, "~> 0.1.5"},
     {:poison, "~> 2.2", override: true},
     {:feedback, in_umbrella: true},
     {:laboratory, github: "paulswartz/laboratory", ref: "cookie_opts"},
     {:zones, in_umbrella: true},
     {:fares, in_umbrella: true},
     {:content, in_umbrella: true},
     {:parallel_stream, "~> 1.0.5"},
     {:bypass, "~> 0.1", only: :test},
     {:dialyxir, ">= 0.3.5", only: [:test, :dev]},
     {:benchfella, "~> 0.3", only: :dev},
     {:excoveralls, "~> 0.5", only: :test},
     {:vehicles, in_umbrella: true},
     {:google_maps, in_umbrella: true},
     {:floki, "~> 0.12.0"},
     {:mochiweb, "~> 2.15.0", override: true},
     {:mock, "~> 0.2.0", only: :test},
     {:system_metrics, in_umbrella: true}]
      # NOTE: mochiweb override added to resolve dependency conflict
      # between html_sanitize_ex (2.12.2) and floki (2.15.0). Overriding does not
      # affect the functions we currently use html_sanitize_ex for. This should be
      # removed as soon as html_sanitize_ex updates to ~> 2.15.0, as it's never
      # used directly in our app.
  end
end
