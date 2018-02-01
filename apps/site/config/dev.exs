use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.

port = String.to_integer(System.get_env("PORT") || "4001")
host = System.get_env("HOST") || "localhost"
static_url = case System.get_env("STATIC_URL") do
  nil -> [ host: System.get_env("STATIC_HOST") || host, port: port]
  static_url -> [ url: static_url ]
end
config :site, SiteWeb.Endpoint,
  http: [port: port],
  static_url: static_url,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    cd: Path.expand("../assets/", __DIR__)]]


# Watch static and templates for browser reloading.
config :site, SiteWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/site_web/views/.*(ex)$},
      ~r{lib/site_web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
config :logger, level: :info, colors: [enabled: true]

# Set a higher stacktrace during development.
# Do not configure such in production as keeping
# and calculating stacktraces is usually expensive.
config :phoenix, :stacktrace_depth, 20

config :site, :wiremock_path, Path.expand("bin/wiremock-standalone-2.14.0.jar")
