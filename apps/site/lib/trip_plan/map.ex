defmodule Site.TripPlan.Map do
  alias TripPlan.{Leg, TransitDetail, Itinerary, NamedPosition}
  alias Stops.Position
  alias GoogleMaps.{MapData, MapData.Marker, MapData.Path}
  alias Site.MapHelpers
  alias Routes.Route

  @type static_map :: String.t
  @type t :: {MapData.t, static_map}
  @type route_mapper :: (String.t -> Route.t | nil)
  @type stop_mapper :: (String.t -> Stops.Stop.t | nil)

  @default_opts [
    route_mapper: &Routes.Repo.get/1,
    stop_mapper: &Stops.Repo.get/1
  ]

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

  @doc """
  Returns the static map data and source URL
  Accepts a function that will return either a
  Route or nil when given a route_id
  """
  @spec itinerary_map(Itinerary.t, Keyword.t) :: t
  def itinerary_map(itinerary, opts \\ []) do
    map_data = itinerary_map_data(itinerary, Keyword.merge(@default_opts, opts))
    {map_data, GoogleMaps.static_map_url(map_data)}
  end

  @spec itinerary_map_data(Itinerary.t, Keyword.t) :: MapData.t
  defp itinerary_map_data(itinerary, opts) do
    markers = markers_for_legs(itinerary.legs, opts)
    paths = Enum.map(itinerary.legs, &build_leg_path(&1, opts[:route_mapper]))

    {600, 600}
    |> MapData.new()
    |> MapData.add_markers(markers)
    |> MapData.add_paths(paths)
  end

  @spec build_leg_path(Leg.t, route_mapper) :: Path.t
  defp build_leg_path(leg, route_mapper) do
    color = leg_color(leg, route_mapper)
    Path.new(leg.polyline, color)
  end

  @spec markers_for_legs([Leg.t], Keyword.t) :: [Marker.t]
  defp markers_for_legs(legs, opts) do
    Enum.flat_map(legs, &build_marker_for_leg(&1, opts))
  end

  @spec build_marker_for_leg(Leg.t, Keyword.t) :: [Marker.t]
  defp build_marker_for_leg(leg, opts) do
    route = case Leg.route_id(leg) do
      :error -> nil
      {:ok, route_id} -> opts[:route_mapper].(route_id)
    end
    Enum.map([leg.from, leg.to], &build_marker_for_leg_position(&1, route, opts[:stop_mapper]))
  end

  @spec build_marker_for_leg_position(NamedPosition.t, Route.t, stop_mapper) :: Marker.t
  defp build_marker_for_leg_position(%NamedPosition{stop_id: nil} = position, route, _stop_mapper) do
    do_build_marker_for_leg_position(position, position.name, route, 0)
  end
  defp build_marker_for_leg_position(%NamedPosition{stop_id: stop_id} = position, route, stop_mapper) do
    tooltip = case stop_mapper.(stop_id) do
      nil -> position.name
      stop -> stop.name
    end
    z_index = if route, do: 1, else: 0
    do_build_marker_for_leg_position(position, tooltip, route, z_index)
  end

  @spec do_build_marker_for_leg_position(NamedPosition.t, String.t, Route.t, non_neg_integer) :: Marker.t
  defp do_build_marker_for_leg_position(leg_position, tooltip, route, z_index) do
    lat = Position.latitude(leg_position)
    lng = Position.longitude(leg_position)
    icon = MapHelpers.map_stop_icon_path(route, :mid)
    Marker.new(lat, lng, tooltip: tooltip, icon: icon, size: :mid, z_index: z_index)
  end

  @spec leg_color(Leg.t, route_mapper) :: String.t
  defp leg_color(%Leg{mode: %TransitDetail{route_id: route_id}}, route_mapper) do
    route_id
    |> route_mapper.()
    |> MapHelpers.route_map_color()
  end
  defp leg_color(_leg, _route_mapper) do
    "000000"
  end
end
