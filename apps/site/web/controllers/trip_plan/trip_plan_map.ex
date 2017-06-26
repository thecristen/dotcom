defmodule Site.TripPlanController.TripPlanMap do
  alias Stops.Position
  alias GoogleMaps.{MapData, MapData.Marker, MapData.Path}

  @moduledoc """
  Handles generating the maps displayed within the TripPlan Controller
  """

  @doc """
  Returns the url for the initial map for the Trip Planner
  """
  @spec initial_map_src() :: String.t
  def initial_map_src do
    {630, 400}
    |> MapData.new(14)
    |> MapData.add_marker(initial_marker())
    |> GoogleMaps.static_map_url()
  end

  @spec initial_marker() :: Marker.t
  defp initial_marker do
    Marker.new(42.360718, -71.05891, visible?: false)
  end

  @doc "Returns the static map data and source URL"
  @spec itinerary_map(TripPlan.Itinerary.t) :: {MapData.t, String.t}
  def itinerary_map(itinerary) do
    map_data = itinerary_map_data(itinerary)
    {map_data, GoogleMaps.static_map_url(map_data)}
  end

  @spec itinerary_map_data(TripPlan.Itinerary.t) :: MapData.t
  defp itinerary_map_data(itinerary) do
    markers = markers_for_legs(itinerary.legs)
    paths = Enum.map(itinerary.legs, &Path.new(&1.polyline, "0064C8"))

    {600, 600}
    |> MapData.new()
    |> MapData.add_markers(markers)
    |> MapData.add_paths(paths)
  end

  @spec markers_for_legs([TripPlan.Leg.t]) :: [Marker.t]
  defp markers_for_legs(legs) do
    Enum.flat_map(legs, &[build_leg_marker(&1.from), build_leg_marker(&1.to)])
  end

  @spec build_leg_marker(Stops.Position.t) :: Marker.t
  defp build_leg_marker(leg_location) do
    Marker.new(Position.latitude(leg_location), Position.longitude(leg_location), size: :small)
  end
end
