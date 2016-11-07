use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :site, Site.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Don't fetch tz data in test mode; can cause a race if we're doing TZ
# operations while it updates.
config :tzdata, :autoupdate, :disabled

config :site, Site.BodyClass,
  mticket_header: "x-mticket"
