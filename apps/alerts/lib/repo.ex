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

  @spec by_route_ids([String.t]) :: [Alerts.Alert.t]
  def by_route_ids(route_ids) do
    route_ids
    |> Store.alert_ids_for_routes()
    |> Store.alerts()
  end

  @spec by_route_types(Enumerable.t) :: [Alerts.Alert.t]
  def by_route_types(types) do
    types
    |> Store.alert_ids_for_route_types()
    |> Store.alerts()
  end

  @spec by_route_id_and_type(String.t, 0..4) :: [Alerts.Alert.t]
  def by_route_id_and_type(route_id, route_type) do
    route_id
    |> Store.alert_ids_for_route_id_and_type(route_type)
    |> Store.alerts()
  end
end
