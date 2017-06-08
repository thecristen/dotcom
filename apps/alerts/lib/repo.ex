defmodule Alerts.Repo do
  use RepoCache, ttl: :timer.minutes(1)

  alias Alerts.Cache.Store

  @spec all(DateTime.t) :: [Alerts.Alert.t]
  def all(now) do
    Store.all_alerts(now)
  end

  @spec banner() :: Alerts.Banner.t | nil
  def banner do
    Store.banner()
  end

  @spec by_route_ids([String.t], DateTime.t) :: [Alerts.Alert.t]
  def by_route_ids(route_ids, now) do
    route_ids
    |> Store.alert_ids_for_routes()
    |> Store.alerts(now)
  end

  @spec by_route_types(Enumerable.t, DateTime.t) :: [Alerts.Alert.t]
  def by_route_types(types, now) do
    types
    |> Store.alert_ids_for_route_types()
    |> Store.alerts(now)
  end

  @spec by_route_id_and_type(String.t, 0..4, DateTime.t) :: [Alerts.Alert.t]
  def by_route_id_and_type(route_id, route_type, now) do
    route_id
    |> Store.alert_ids_for_route_id_and_type(route_type)
    |> Store.alerts(now)
  end
end
