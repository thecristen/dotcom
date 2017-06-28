defmodule Site.TripPlan.Map do
  alias TripPlan.{Leg, TransitDetail, Itinerary}
  alias Stops.Position
  alias GoogleMaps.{MapData, MapData.Marker, MapData.Path}
  alias Site.MapHelpers

  @type static_map :: String.t
  @type t :: {MapData.t, static_map}
  @type route_map :: %{optional(Routes.Route.id_t) => Routes.Route.t}

  @moduledoc """
  Handles generating the maps displayed within the TripPlan Controller
  """

  @doc """
  Returns the url for the initial map for the Trip Planner
  """
  @spec initial_map_src() :: static_map
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
  @spec itinerary_map(Itinerary.t, route_map) :: t
  def itinerary_map(itinerary, route_map) do
    map_data = itinerary_map_data(itinerary, route_map)
    {map_data, GoogleMaps.static_map_url(map_data)}
  end

  @spec itinerary_map_data(Itinerary.t, route_map) :: MapData.t
  defp itinerary_map_data(itinerary, route_map) do
    markers = markers_for_legs(itinerary.legs)
    paths = Enum.map(itinerary.legs, &build_leg_path(&1, route_map))

    {600, 600}
    |> MapData.new()
    |> MapData.add_markers(markers)
    |> MapData.add_paths(paths)
  end

  @spec build_leg_path(Leg.t, route_map) :: Path.t
  defp build_leg_path(leg, route_map) do
    color = leg_color(leg, route_map)
    Path.new(leg.polyline, color)
  end

  @spec markers_for_legs([Leg.t]) :: [Marker.t]
  defp markers_for_legs(legs) do
    Enum.flat_map(legs, &[build_leg_marker(&1.from), build_leg_marker(&1.to)])
  end

  @spec build_leg_marker(Stops.Position.t) :: Marker.t
  defp build_leg_marker(leg_location) do
    Marker.new(Position.latitude(leg_location), Position.longitude(leg_location), size: :small)
  end

  @spec leg_color(Leg.t, route_map) :: String.t
  defp leg_color(%Leg{mode: %TransitDetail{route_id: route_id}}, route_map) do
    route_map
    |> Map.get(route_id)
    |> MapHelpers.route_map_color()
  end
  defp leg_color(_leg, _route_map) do
    "000000"
  end
end
