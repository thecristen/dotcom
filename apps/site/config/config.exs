# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :site, Site.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "4DTl03knjPRXF9QYrTqcVRZUy8hN5gS6x6rN1mIImpo1rcN79d77ZAfShyVqDzx/",
  render_errors: [accepts: ~w(html json), layout: {Site.LayoutView, "app.html"}],
  pubsub: [name: Site.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :phoenix, :gzippable_exts, ~w(.txt .html .js .css .svg)

# Configures Elixir's Logger
config :logger, :console,
  format: "$date $time $metadata[$level] $message\n",
  metadata: [:request_id]

config :site, Site.ViewHelpers,
  google_api_key: System.get_env("GOOGLE_API_KEY"),
  google_tag_manager_id: System.get_env("GOOGLE_TAG_MANAGER_ID"),
  feedback_form_url:
    "https://docs.google.com/a/mbtace.com/forms/d/e/1FAIpQLScjM7vVFw-5qNZsKC3CNy7xzOAg0i5atkn_tWhkzZkw_oQUyg/viewform"

config :site, GoogleMaps,
  client_id: System.get_env("GOOGLE_MAPS_CLIENT_ID") || "",
  signing_key: System.get_env("GOOGLE_MAPS_SIGNING_KEY") || ""

config :laboratory,
  features: [
    {:predictions, "Predictions", "Enables real-time information in schedules"}
  ],
  cookie: [
    max_age: 3600 * 24 * 30, # one month,
    http_only: true
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
