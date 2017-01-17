# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

if Mix.env == :prod do
  config :google_maps,
    google_api_key: "${GOOGLE_API_KEY}",
    client_id: "${GOOGLE_MAPS_CLIENT_ID}",
    signing_key: "${GOOGLE_MAPS_SIGNING_KEY}"
else
  config :google_maps,
    google_api_key: System.get_env("GOOGLE_API_KEY"),
    client_id: System.get_env("GOOGLE_MAPS_CLIENT_ID") || "",
    signing_key: System.get_env("GOOGLE_MAPS_SIGNING_KEY") || ""
end
