defmodule Stops.Api do
  @moduledoc """
  Wrapper around the remote stop information service.
  """
  alias Stops.StationInfoApi
  alias Stops.Stop

  @vending_machine_stations ["place-north", "place-sstat", "place-bbsta", "place-portr", "place-mlmnl",
                             "Lynn", "Worcester", "place-rugg", "place-forhl", "place-jfk", "place-qnctr",
                             "place-brntn"]
                             |> Map.new(&{&1, true})

  @charlie_card_stations [
    "place-alfcl",
    "place-armnl",
    "place-asmnl",
    "place-bbsta",
    "64000",
    "place-forhl",
    "place-harsq",
    "place-north",
    "place-ogmnl",
    "place-pktrm",
    "place-rugg"
  ]
  |> Map.new(&{&1, true})


  @spec all :: [Stop.t]
  def all do
    StationInfoApi.all
    |> map_json_api
  end

  @spec by_gtfs_id(String.t) :: Stop.t | nil
  def by_gtfs_id(gtfs_id) do
    station_info_task = Task.async fn -> gtfs_id
      |> StationInfoApi.by_gtfs_id
      |> map_json_api
      |> List.first
    end
    v3_task = Task.async fn ->
      gtfs_id
      |> V3Api.Stops.by_gtfs_id
      |> extract_v3_response
    end
    merge_v3(Task.await(station_info_task), Task.await(v3_task))
  end

  defp map_json_api(%JsonApi{data: data}) do
    data
    |> Enum.map(&parse_stop/1)
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
      |> map_json_api
      |> List.first
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

  defp parse_stop(%JsonApi.Item{attributes: attributes, relationships: relationships}) do
    id = attributes["gtfs_id"]
    %Stop{
      id: id,
      name: attributes["name"],
      address: attributes["address"],
      note: attributes["note"],
      accessibility: attributes["accessibility"],
      images: images(relationships["images"]),
      parking_lots: parking_lots(relationships),
      station?: true,
      has_fare_machine?: Map.get(@vending_machine_stations, id, false),
      has_charlie_card_vendor?: Map.get(@charlie_card_stations, id, false)
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
    # previous version of the Stop Info API
    manager = parse_manager(first.relationships["manager"])
    rate = first.attributes["rate"]
    note = first.attributes["note"]
    [
      %Stop.ParkingLot{
        name: "",
        average_availability: "",
        rate: rate,
        note: note,
        manager: manager,
        spots: parkings |> Enum.map(fn parking ->
          %Stop.Parking{
            type: parking.attributes["type"],
            spots: parking.attributes["spots"]} end)}
    ]
  end

  defp parse_parking_lot(%JsonApi.Item{attributes: attributes, relationships: relationships}) do
    %Stop.ParkingLot{
      name: attributes["name"],
      average_availability: attributes["average_availability"],
      rate: attributes["rate"],
      note: attributes["note"],
      manager: parse_manager(relationships["manager"]),
      spots: Enum.map(attributes["spots"], &parse_spot/1)
    }
  end

  defp parse_spot(%{"type" => type, "spots" => spots}) do
    %Stop.Parking{
      type: type,
      spots: spots
    }
  end

  defp parse_manager([%JsonApi.Item{attributes: attributes}]) do
    %Stop.Manager{
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
      %Stop.Image{
        description: image.attributes["description"],
        url: image.attributes["url"],
        sort_order: image.attributes["sort_order"]}
    end)
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
