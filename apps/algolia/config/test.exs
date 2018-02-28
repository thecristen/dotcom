use Mix.Config

config :algolia, :repos,
  stops: Algolia.MockStopsRepo,
  routes: Algolia.MockRoutesRepo

config :algolia, :indexes, [
  Algolia.MockObjects
]
