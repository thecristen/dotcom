use Mix.Config

config :algolia, :keys,
  app_id: "${ALGOLIA_APP_ID}",
  admin: "${ALGOLIA_ADMIN_KEY}",
  search: "${ALGOLIA_SEARCH_KEY}",
