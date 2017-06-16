defmodule Site.TripPlanView do
  use Site.Web, :view
  alias Stops.Position
  alias TripPlan.{Leg, TransitDetail, PersonalDetail}

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

  def itinerary_map_src(itinerary) do
    path_opts = for leg <- itinerary.legs do
      {:path, "enc:#{leg.polyline}"}
    end
    marker_opts = for leg <- itinerary.legs do
      markers = [
        "size:small",
        "#{Position.latitude(leg.from)},#{Position.longitude(leg.from)}",
        "#{Position.latitude(leg.to)},#{Position.longitude(leg.to)}"
      ]
      {:markers, Enum.join(markers, "|")}
    end

    GoogleMaps.static_map_url(600, 600, Enum.concat(path_opts, marker_opts))
  end

  def initial_map_src do
    GoogleMaps.static_map_url(630, 400, [center: "Boston, MA", zoom: 14])
  end
end
