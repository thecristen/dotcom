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
    map_data = %MapData{
      markers: Enum.flat_map(itinerary.legs, &[build_leg_marker(&1.from), build_leg_marker(&1.to)]),
      paths: Enum.map(itinerary.legs, & %Path{polyline: &1.polyline, color: "#fff"}),
      width: 600,
      height: 600,
      zoom: 14
    }
    GoogleMaps.static_map_url(map_data)
  end

  defp build_leg_marker(leg_location) do
    %Marker{
      size: :small,
      visible?: true,
      latitude: Position.latitude(leg_location),
      longitude: Position.longitude(leg_location),
      icon: nil
    }
  end

  def initial_map_src do
    #GoogleMaps.static_map_url(630, 400, [center: "Boston, MA", zoom: 14])
    map_data = %MapData {
      height: 400,
      width: 630,
      zoom: 14,
      markers: [initial_marker()]
    }
    GoogleMaps.static_map_url(map_data)
  end

  defp initial_marker do
    %Marker {
      visible?: false,
      latitude: 42.360718,
      longitude: -71.05891
    }
  end
end
