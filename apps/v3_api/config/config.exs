# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :v3_api,
  base_url: {:system, "V3_URL", "https://dev.api.mbtace.com/"},
  api_key: {:system, "V3_API_KEY"}
