use Mix.Config

config :news,
  repo: News.Repo.Ets,
  post_url: "${NEWS_POST_URL}"
