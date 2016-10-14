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
     deps: deps]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    apps = [:phoenix, :phoenix_pubsub, :phoenix_html, :cowboy, :logger, :gettext,
            :stations, :routes, :alerts, :news, :schedules, :predictions, :timex,
            :inflex, :html_sanitize_ex, :logger_logentries_backend,
            :logster, :sizeable, :feedback, :zones]

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
     {:timex, ">= 2.0.0"},
     {:stations, in_umbrella: true},
     {:routes, in_umbrella: true},
     {:alerts, in_umbrella: true},
     {:news, in_umbrella: true},
     {:schedules, in_umbrella: true},
     {:ehmon, git: "https://github.com/heroku/ehmon.git", tag: "v4", only: :prod},
     {:predictions, in_umbrella: true},
     {:exrm, ">= 0.0.0"},
     {:inflex, "~> 1.7.0"},
     {:html_sanitize_ex, "~> 1.0.0"},
     {:logster, "~> 0.3.0"},
     {:logger_logentries_backend, github: "paulswartz/logger_logentries_backend"},
     {:excheck, "~> 0.5", only: :test},
     {:triq, github: "triqng/triq", only: :test},
     {:sizeable, "~> 0.1.5"},
     {:poison, "~> 2.2", override: true},
     {:feedback, in_umbrella: true},
     {:laboratory, github: "paulswartz/laboratory", ref: "cookie_opts"},
     {:porcelain, "~> 2.0"},
     {:zones, in_umbrella: true}
    ]
  end
end
