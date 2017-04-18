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

  @spec by_gtfs_id(String.t) :: Stop.t | nil
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

  def by_route_type({route_type, opts}) do
    [
      route_type: route_type,
      include: "parent_station",
    ]
    |> Keyword.merge(opts)
    |> V3Api.Stops.all
    |> merge_station_info_api
  end


  defp merge_station_info_api({:error, _} = error) do
    error
  end
  defp merge_station_info_api(api) do
    api.data
    |> Enum.uniq_by(&v3_id/1)
    |> Task.async_stream(fn (item) ->
      item
      |> v3_id
      |> StationInfoApi.by_gtfs_id
      |> merge_v3(item)
    end)
    |> Enum.map(fn {:ok, stop} -> stop end)
  end

  defp v3_id(%JsonApi.Item{relationships: %{"parent_station" => [%JsonApi.Item{id: parent_id}]}}) do
    parent_id
  end
  defp v3_id(item) do
    item.id
  end

  defp v3_name(%JsonApi.Item{relationships: %{"parent_station" => [%JsonApi.Item{attributes: %{"name" => parent_name}}]}}) do
    parent_name
  end
  defp v3_name(item) do
    item.attributes["name"]
  end

  defp extract_v3_response({:error, _}) do
    # In the case of a failed V3 response, just return nil
    nil
  end
  defp extract_v3_response(%JsonApi{data: [item | _]}) do
    item
  end

  defp merge_v3(station_info_stop, v3_stop_response)
  defp merge_v3(stop, nil), do: stop
  defp merge_v3(nil, stop) do
    accessibility = if stop.attributes["wheelchair_boarding"] == 1 do
      ["accessible"]
    else
      []
    end
    %Stop{
      id: v3_id(stop),
      name: v3_name(stop),
      accessibility: accessibility,
      parking_lots: [],
      latitude: stop.attributes["latitude"],
      longitude: stop.attributes["longitude"]
    }
  end
  defp merge_v3(stop, %JsonApi.Item{attributes: %{"latitude" => latitude, "longitude" => longitude}} = item) do
    %Stop{stop |
          latitude: latitude,
          longitude: longitude,
          name: v3_name(item)}
  end
end
