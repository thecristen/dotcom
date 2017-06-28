defmodule Site.TripPlanView do
  use Site.Web, :view
  alias TripPlan.{Leg, TransitDetail, PersonalDetail}

  @spec rendered_location_error(Plug.Conn.t, TripPlan.Query.t | nil, :from | :to) :: Phoenix.HTML.safe
  def rendered_location_error(conn, query_or_nil, location_field)
  def rendered_location_error(_conn, _query_or_nil, _location_field) do
    ""
  end

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

  def location_input_class(params, key) do
    if TripPlan.Query.fetch_lat_lng(params, Atom.to_string(key)) == :error do
      ""
    else
      "trip-plan-current-location"
    end
  end
end
