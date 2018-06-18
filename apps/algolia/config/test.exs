use Mix.Config

config :algolia, :repos,
  stops: Algolia.MockStopsRepo,
  routes: Algolia.MockRoutesRepo

config :algolia, :indexes, [
  Algolia.MockObjects
]

config :algolia, :click_analytics_url, :not_set

config :algolia, :index_suffix, "_test"
