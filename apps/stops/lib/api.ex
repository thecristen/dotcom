defmodule Stops.Api do
  @moduledoc """
  Wrapper around the remote stop information service.
  """
  alias Stops.StationInfoApi
  alias Stops.Stop

  @spec all :: [Stop.t]
  def all do
    StationInfoApi.all
  end

  @doc """
  Returns a Stop by its GTFS ID.

  If a stop is found, we return `{:ok, %Stop{}}`. If no stop exists with that
  ID, we return `{:ok, nil}`. If there's an error fetching data, we return
  that as an `{:error, any}` tuple.
  """
  @spec by_gtfs_id(String.t) :: {:ok, Stop.t | nil} | {:error, any}
  def by_gtfs_id(gtfs_id) do
    station_info_task = Task.async fn ->
      StationInfoApi.by_gtfs_id(gtfs_id)
    end
    v3_task = Task.async fn ->
      gtfs_id
      |> V3Api.Stops.by_gtfs_id
      |> extract_v3_response
    end
    merge_v3(Task.await(station_info_task), Task.await(v3_task))
  end

  @spec by_route({Routes.Route.id_t, 0 | 1, Keyword.t}) :: [Stop.t]
  def by_route({route_id, direction_id, opts}) do
    params = [
      route: route_id,
      include: "parent_station",
      direction_id: direction_id
    ]

    params
    |> Keyword.merge(opts)
    |> V3Api.Stops.all
    |> merge_station_info_api
  end

  @spec by_route_type({0..4, Keyword.t}) :: [Stop.t]
  def by_route_type({route_type, opts}) do
    [
      route_type: route_type,
      include: "parent_station",
    ]
    |> Keyword.merge(opts)
    |> V3Api.Stops.all
    |> merge_station_info_api
  end

  @spec merge_station_info_api(JsonApi.t | {:error, any}) :: [Stop.t]
  defp merge_station_info_api({:error, _} = error) do
    error
  end
  defp merge_station_info_api(api) do
    api.data
    |> Enum.uniq_by(&v3_id/1)
    |> Task.async_stream(&get_station_info/1)
    |> Enum.map(fn {:ok, stop} -> stop end)
  end

  @spec get_station_info(JsonApi.Item.t) :: Stop.t | nil
  def get_station_info(%JsonApi.Item{} = stop) do
    {:ok, merged} = stop
    |> v3_id
    |> StationInfoApi.by_gtfs_id
    |> merge_v3({:ok, stop})
    merged
  end

  @spec v3_id(JsonApi.Item.t) :: Stop.id_t
  defp v3_id(%JsonApi.Item{relationships: %{"parent_station" => [%JsonApi.Item{id: parent_id}]}}) do
    parent_id
  end
  defp v3_id(item) do
    item.id
  end

  @spec v3_name(JsonApi.Item.t) :: String.t
  defp v3_name(%JsonApi.Item{relationships: %{"parent_station" => [%JsonApi.Item{attributes: %{"name" => parent_name}}]}}) do
    parent_name
  end
  defp v3_name(item) do
    item.attributes["name"]
  end

  @spec extract_v3_response(JsonApi.t) :: {:ok, JsonApi.Item.t} | {:error, any}
  defp extract_v3_response(%JsonApi{data: [item | _]}) do
    {:ok, item}
  end
  defp extract_v3_response({:error, _} = error) do
    error
  end

  @spec merge_v3(Stop.t | nil, {:ok, JsonApi.Item.t} | {:error, any}) :: {:ok, Stop.t | nil} | {:error, any}
  def merge_v3(station_info_stop, v3_stop_response)
  def merge_v3(nil, {:ok, item}) do
    stop = %Stop{
      id: v3_id(item),
      name: v3_name(item),
      accessibility: merge_accessibility([],
        item.attributes),
      parking_lots: [],
      latitude: item.attributes["latitude"],
      longitude: item.attributes["longitude"]
    }
    {:ok, stop}
  end
  def merge_v3(stop, {:ok, item}) do
    stop = %{stop |
             latitude: item.attributes["latitude"],
             longitude: item.attributes["longitude"],
             accessibility: merge_accessibility(stop.accessibility,
               item.attributes),
             name: v3_name(item)}
    {:ok, stop}
  end
  def merge_v3(%Stop{} = stop, _) do
    {:ok, stop}
  end
  def merge_v3(_stop, {:error, [%JsonApi.Error{code: "not_found"} | _]}) do
    {:ok, nil}
  end
  def merge_v3(_stop, error) do
    error
  end

  defp merge_accessibility(accessibility, stop_attributes)
  defp merge_accessibility(accessibility, %{"wheelchair_boarding" => 0}) do
    # if GTFS says we don't know what the accessibility situation is, then
    # add "unknown" as the first attribute
    ["unknown" | accessibility]
  end
  defp merge_accessibility(accessibility, %{"wheelchair_boarding" => 1}) do
    # make sure "accessibile" is the first list option
    ["accessible" | accessibility]
  end
  defp merge_accessibility(accessibility, _) do
    accessibility
  end
end
