defmodule Site.TripPlanView do
  use Site.Web, :view
  alias Stops.Position
  alias TripPlan.{Leg, TransitDetail, PersonalDetail}
  alias GoogleMaps.MapData
  alias GoogleMaps.MapData.{Marker, Path}

  def optional_position({:ok, _}), do: ""
  def optional_position({:error, {:too_many_results, results}}) do
    content_tag :div do
      [
        "Too many results returned",
        tag(:br),
        content_tag :ul do
          for result <- results do
            content_tag :li, [result.name]
          end
        end
      ]
    end
  end
  def optional_position({:error, error}) do
    "Error: #{inspect error}"
  end

  @doc "A small display representing the travel on a given Leg"
  @spec leg_feature(TripPlan.Leg.t, %{Routes.Route.id_t => Routes.Route.t}) :: Phoenix.HTML.Safe.t
  def leg_feature(%Leg{mode: %TransitDetail{} = mode}, route_map) do
    icon = route_map
    |> Map.get(mode.route_id)
    |> Routes.Route.icon_atom
    svg_icon_with_circle(%SvgIconWithCircle{icon: icon, class: "icon-small"})
  end
  def leg_feature(%Leg{mode: %PersonalDetail{type: :walk}}, _) do
    svg("walk.svg")
  end
  def leg_feature(%Leg{mode: %PersonalDetail{type: :drive}}, _) do
    svg("car.svg")
  end

  defp itinerary_map_src(itinerary) do
    markers = markers_for_legs(itinerary.legs)
    paths = Enum.map(itinerary.legs, &Path.new(&1.polyline))

    600
    |> MapData.new(600)
    |> MapData.add_markers(markers)
    |> MapData.add_paths(paths)
    |> GoogleMaps.static_map_url()
  end

  defp markers_for_legs(legs) do
    Enum.flat_map(legs, &[build_leg_marker(&1.from), build_leg_marker(&1.to)])
  end

  defp build_leg_marker(leg_location) do
    Marker.new(Position.latitude(leg_location), Position.longitude(leg_location), size: :small)
  end

  def initial_map_src do
    630
    |> MapData.new(400, 14)
    |> add_initial_marker()
    |> GoogleMaps.static_map_url()
  end

  defp add_initial_marker(map_data) do
    marker = Marker.new(42.360718, -71.05891, visible?: false)
    MapData.add_marker(map_data, marker)
  end
end
