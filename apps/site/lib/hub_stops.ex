defmodule HubStops do
  @moduledoc """
  Represents a list of Hub Stops
  """

  alias Routes.Route

  @commuter_hubs  [
    {"place-sstat", "/images/stops/south_station.jpg"},
    {"place-north", "/images/stops/north_station_commuter.jpg"},
    {"place-bbsta", "/images/stops/back_bay.jpg"}
  ]
  @red_line_hubs  [
    {"place-sstat", "/images/stops/south_station.jpg"},
    {"place-pktrm", "/images/stops/park_street.jpg"},
    {"place-dwnxg", "/images/stops/downtown_crossing.jpg"}
  ]
  @green_line_hubs [
    {"place-north","/images/stops/north_station.jpg"},
    {"place-pktrm", "/images/stops/park_street.jpg"},
    {"place-gover","/images/stops/government_center.jpg"}
  ]
  @orange_line_hubs [
    {"place-north", "/images/stops/north_station.jpg"},
    {"place-bbsta", "/images/stops/back_bay.jpg"},
    {"place-rugg", "/images/stops/ruggles.jpg"}
  ]
  @blue_line_hubs [
    {"place-state","/images/stops/state_street.jpg"},
    {"place-wondl","/images/stops/wonderland.jpg"},
    {"place-aport","/images/stops/airport.jpg"}
  ]

  @hub_map %{
    "Red" => @red_line_hubs,
    "Blue" => @blue_line_hubs,
    "Green" => @green_line_hubs,
    "Orange" => @orange_line_hubs
  }

  @doc """
  Returns a list of HubStops for the given mode that are
  found in the given list of DetailedStopGroup's
  """
  @spec mode_hubs(String.t, [DetailedStopGroup.t]) :: [HubStop.t]
  def mode_hubs("commuter_rail", route_stop_pairs) do
    all_mode_stops = Enum.flat_map(route_stop_pairs, fn {_route, stops} -> stops end)
    @commuter_hubs
    |> Enum.map(&build_hub_stop(&1, all_mode_stops))
  end
  def mode_hubs(_mode, _route_stop_pairs) do
    []
  end

  @doc """
  Returns a map of %{route_id -> HubStopList} which represents all
  the hubstops for all routes found in the given list of DetailedStopGroup
  """
  @spec route_hubs([DetailedStopGroup.t]) :: %{String.t => [HubStop.t]}
  def route_hubs(route_stop_pairs) do
    Map.new(route_stop_pairs, &do_from_stop_info/1)
  end

  @spec do_from_stop_info(DetailedStopGroup.t) :: {String.t, [HubStop.t]}
  defp do_from_stop_info({%Route{id: route_id}, detailed_stops}) when route_id in ["Red", "Blue", "Green", "Orange"] do
    hub_stops = @hub_map
    |> Map.get(route_id)
    |> Task.async_stream(&build_hub_stop(&1, detailed_stops))
    |> Enum.map(fn {:ok, hub_stop} -> hub_stop end)
    {route_id, hub_stops}
  end
  defp do_from_stop_info({%Route{id: route_id}, _}), do: {route_id, []}

  @spec build_hub_stop({String.t, String.t}, [DetailedStop.t]) :: HubStop.t
  defp build_hub_stop({stop_id, path}, detailed_stops) do
    %HubStop{
      detailed_stop: Enum.find(detailed_stops, & &1.stop.id == stop_id),
      image_path: path
    }
  end
end
