defmodule Stations.Api do
  @moduledoc """
  Wrapper around the remote station information service.
  """
  alias Stations.StationInfoApi
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
      |> V3Api.Stops.by_gtfs_id
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
      images: images(relationships["images"]),
      parking_lots: parking_lots(relationships)
    }
  end

  defp parking_lots(%{"parking_lots" => lots}) do
    lots
    |> Enum.map(&parse_parking_lot/1)
  end
  defp parking_lots(%{"parkings" => []}) do
    []
  end
  defp parking_lots(%{"parkings" => [first|_] = parkings}) do
    # previous version of the Station Info API
    manager = parse_manager(first.relationships["manager"])
    rate = first.attributes["rate"]
    note = first.attributes["note"]
    [
      %Station.ParkingLot{
        name: "",
        average_availability: "",
        rate: rate,
        note: note,
        manager: manager,
        spots: parkings |> Enum.map(fn parking ->
          %Station.Parking{
            type: parking.attributes["type"],
            spots: parking.attributes["spots"]} end)}
    ]
  end

  defp parse_parking_lot(%JsonApi.Item{attributes: attributes, relationships: relationships}) do
    %Station.ParkingLot{
      name: attributes["name"],
      average_availability: attributes["average_availability"],
      rate: attributes["rate"],
      note: attributes["note"],
      manager: parse_manager(relationships["manager"]),
      spots: Enum.map(attributes["spots"], &parse_spot/1)
    }
  end

  defp parse_spot(%{"type" => type, "spots" => spots}) do
    %Station.Parking{
      type: type,
      spots: spots
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

  defp images(nil), do: []
  defp images(items) do
    items
    |> Enum.map(fn image ->
      %Station.Image{
        description: image.attributes["description"],
        url: image.attributes["url"],
        sort_order: image.attributes["sort_order"]}
    end)
  end

  defp merge_v3(nil, _) do
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
