defmodule Alerts.Repo do
  use RepoCache, ttl: :timer.minutes(1)

  alias Alerts.Cache.Store

  @spec all() :: [Alerts.Alert.t]
  def all do
    Store.all_alerts()
  end

  @spec banner() :: Alerts.Banner.t | nil
  def banner do
    Store.banner()
  end
end
