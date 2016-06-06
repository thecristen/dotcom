defmodule Stations.Api do
  @moduledoc """
  Wrapper around the remote station information service.
  """
  alias Stations.StationInfoApi
  alias Stations.V3Api
  alias Stations.Station

  @spec all :: [Station.t]
  def all do
    StationInfoApi.all
    |> map_json_api
  end

  @spec by_gtfs_id(String.t) :: Station.t | nil
  def by_gtfs_id(gtfs_id) do
    station_info_task = Task.async fn -> gtfs_id
      |> StationInfoApi.by_gtfs_id
      |> map_json_api
      |> List.first
    end
    v3_task = Task.async fn ->
      gtfs_id
      |> V3Api.by_gtfs_id
    end
    merge_v3(Task.await(station_info_task), Task.await(v3_task))
  end

  defp map_json_api(%JsonApi{data: data}) do
    data
    |> Enum.map(&parse_station/1)
  end

  defp parse_station(%JsonApi.Item{attributes: attributes, relationships: relationships}) do
    %Station{
      id: attributes["gtfs_id"],
      name: attributes["name"],
      address: attributes["address"],
      note: attributes["note"],
      accessibility: attributes["accessibility"],
      parkings: Enum.map(relationships["parkings"], &parse_parking/1)
    }
  end

  defp parse_parking(%JsonApi.Item{attributes: attributes, relationships: relationships}) do
    %Station.Parking{
      type: attributes["type"],
      spots: attributes["spots"],
      rate: attributes["rate"],
      note: attributes["note"],
      manager: parse_manager(relationships["manager"])
    }
  end

  defp parse_manager([%JsonApi.Item{attributes: attributes}]) do
    %Station.Manager{
      name: attributes["name"],
      website: attributes["website"],
      phone: attributes["phone"],
      email: attributes["email"]
    }
  end
  defp parse_manager([]) do
    nil
  end

  defp merge_v3(station, %JsonApi{data: [%JsonApi.Item{attributes: %{"latitude" => latitude, "longitude" => longitude}}]}) do
    %Station{station | latitude: latitude, longitude: longitude}
  end
  defp merge_v3(station, %{status_code: 404}) do
    # failed v3 response, just return the station as-is
    station
  end
end
