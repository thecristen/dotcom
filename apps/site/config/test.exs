use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :site, SiteWeb.Endpoint,
  http: [port: 4002],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

# Don't fetch tz data in test mode; can cause a race if we're doing TZ
# operations while it updates.
config :tzdata, :autoupdate, :disabled

config :wallaby,
  screenshot_on_failure: true,
  driver: Wallaby.Experimental.Chrome,
  chrome: [
    headless: true
  ],
  # This allows tests that throw javascript errors to be considered 'passing'
  # We currently have some icon issues that throw JS errors. In order for
  # system tests to pass we need this setting.
  # This should be removed when this ticket is closed
  # https://app.asana.com/0/555089885850811/666915490202151
  js_errors: false
