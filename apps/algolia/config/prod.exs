use Mix.Config

config :algolia, :keys,
  app_id: "${ALGOLIA_APP_ID}",
  admin: "${ALGOLIA_ADMIN_KEY}",
  search: "${ALGOLIA_SEARCH_KEY}",
  places: [
    app_id: "${ALGOLIA_PLACES_APP_ID}",
    search: "${ALGOLIA_PLACES_SEARCH_KEY}"
  ]
