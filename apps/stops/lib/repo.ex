defmodule Stops.Repo do
  @moduledoc """
  Matches the Ecto API, but fetches Stops from the Stop Info API instead.
  """
  use RepoCache, ttl: :timer.hours(1)
  alias Stops.Position
  alias Stops.Stop

  @type stop_feature :: Routes.Route.route_type | Routes.Route.subway_lines_type | :access | :parking_lot

  def stations do
    cache [], fn _ ->
      Stops.Api.all
      |> Enum.sort_by(&(&1.name))
    end
  end

  def get(id) do
    cache id, &Stops.Api.by_gtfs_id/1
  end

  def get!(id) do
    case get(id) do
      nil -> raise Stops.NotFoundError, message: "Could not find stop #{id}"
      stop -> stop
    end
  end

  @spec closest(Position.t) :: [Stop.t]
  def closest(position) do
    Stops.Nearby.nearby(position)
  end

  @spec by_route(Routes.Route.id_t, 0 | 1, Keyword.t) :: [Stop.t] | {:error, any}
  def by_route(route_id, direction_id, opts \\ []) do
    cache {route_id, direction_id, opts}, &Stops.Api.by_route/1
  end

  @spec by_routes([Routes.Route.id_t], 0 | 1, Keyword.t) :: [Stop.t] | {:error, any}
  def by_routes(route_ids, direction_id, opts \\ []) when is_list(route_ids) do
    # once the V3 API supports multiple route_ids in this field, we can do it
    # as a single lookup -ps
    route_ids
    |> Task.async_stream(&by_route(&1, direction_id, opts))
    |> Enum.flat_map(fn
      {:ok, stops} -> stops
      _ -> []
    end)
    |> Enum.uniq
  end

  @spec by_route_type(Routes.Route.t, Keyword.t):: [Stop.t] | {:error, any}
  def by_route_type(route_type, opts \\ []) do
    cache {route_type, opts}, &Stops.Api.by_route_type/1
  end

  def stop_exists_on_route?(stop_id, route, direction_id) do
    route
    |> by_route(direction_id)
    |> Enum.any?(&(&1.id == stop_id))
  end

  @doc """
  Returns a list of the features associated with the given stop
  """
  @spec stop_features(Stop.t) :: [stop_feature]
  def stop_features(stop) do
    [
      route_features(stop.id),
      parking_features(stop.parking_lots),
      accessibility_features(stop.accessibility)
    ]
    |> Enum.concat()
    |> Enum.sort_by(&sort_feature_icons/1)
  end

  defp parking_features([]), do: []
  defp parking_features(_parking_lots), do: [:parking_lot]

  @spec route_features(String.t) :: [stop_feature]
  defp route_features(stop_id) do
    stop_id
    |> Routes.Repo.by_stop
    |> Enum.map(&Routes.Route.icon_atom/1)
    |> Enum.uniq()
  end

  @spec accessibility_features([String.t]) :: [:access]
  defp accessibility_features(["accessible" | _]), do: [:access]
  defp accessibility_features(_), do: []

  @spec sort_feature_icons(atom) :: integer
  defp sort_feature_icons(:commuter_rail), do: 0
  defp sort_feature_icons(:bus), do: 2
  defp sort_feature_icons(:access), do: 3
  defp sort_feature_icons(:parking_lot), do: 4
  defp sort_feature_icons(_), do: 1
end

defmodule Stops.NotFoundError do
  @moduledoc "Raised when we don't find a stop with the given GTFS ID"
  defexception [:message]
end
