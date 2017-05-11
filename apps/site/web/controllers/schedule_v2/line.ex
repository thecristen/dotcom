defmodule Site.ScheduleV2Controller.Line do

  import Plug.Conn, only: [assign: 3]
  import Site.Router.Helpers
  require Routes.Route

  def init([]), do: []

  def call(%Plug.Conn{assigns: %{route: %{id: "Green"}}} = conn, _args) do
    route = GreenLine.green_line()
    stops_on_routes = GreenLine.stops_on_routes(0)
    stops = GreenLine.all_stops(stops_on_routes)
    shapes = GreenLine.branch_ids
    |> Enum.join(",")
    |> Routes.Repo.get_shapes(conn.assigns.direction_id)

    {before_branch, after_branch} = Enum.split_while(stops, & &1.id != "place-coecl")
    routes_for_stops = GreenLine.routes_for_stops(stops_on_routes) # Inverse Map
    expanded = conn.params["expanded"]
    expanded_stops = green_line_branches(after_branch, routes_for_stops, expanded)
    active_lines = active_lines(stops_on_routes)

    conn
    |> assign(:stop_list_template, "_stop_list_green.html")
    |> assign(:stops_on_routes, stops_on_routes)
    |> assign(:stops_with_expands, before_branch ++ insert_expands(expanded_stops, active_lines))
    |> assign(:expanded, expanded)
    |> assign(:active_lines, active_lines)
    |> assign(:stop_features, stop_features(stops, route))
    |> assign(:map_img_src, map_img_src(conn.assigns.all_stops, route.type, route.id, shapes))
    |> assign(:route, route)
  end
  def call(%Plug.Conn{assigns: %{route: %Routes.Route{id: "Red"} = route}} = conn, _args) do
    shapes = Routes.Repo.get_shapes(route.id, 0)
    [
      %Stops.RouteStops{branch: nil, stops: shared_stops},
      %Stops.RouteStops{branch: "Braintree", stops: braintree_stops},
      %Stops.RouteStops{branch: "Ashmont", stops: ashmont_stops}
    ] = route.id
    |> Stops.Repo.by_route(0)
    |> Stops.RouteStops.by_direction(shapes, route, 0)

    [braintree, ashmont] = [braintree_stops, ashmont_stops]
    |> Enum.map(fn stops ->
      branch = stops |> List.first() |> Map.get(:branch)
      if conn.query_params["expanded"] == branch, do: stops, else: [List.last(stops)]
    end)

    conn
    |> assign(:stop_list_template, "_stop_list_red.html")
    |> assign(:stops, shared_stops)
    |> assign(:merge_stop_id, "place-jfk")
    |> assign(:braintree_branch_stops, braintree)
    |> assign(:ashmont_branch_stops, ashmont)
    |> assign(:map_img_src, map_img_src((shared_stops ++ braintree_stops ++ ashmont_stops) |> Enum.map(& &1.station_info), conn.assigns.route.type, route.id, shapes))
  end
  def call(%Plug.Conn{assigns: %{direction_id: direction_id, route: %Routes.Route{type: 3} = route}} = conn, _args) do
    shapes = Routes.Repo.get_shapes(route.id, direction_id)
    shape = get_shape(shapes, conn.query_params["variant"])
    route_stops = get_route_stops([shape], route, direction_id)
    show_variant_selector = case shapes do
      [_, _ | _] -> true
      _ -> false
    end

    conn
    |> assign(:stop_list_template, "_stop_list.html")
    |> assign(:stops, route_stops)
    |> assign(:shapes, shapes)
    |> assign(:active_shape, shape)
    |> assign(:show_variant_selector, show_variant_selector)
    |> assign(:map_img_src, map_img_src(route_stops |> Enum.map(& &1.station_info), route.type, route.id, [shape]))
  end
  def call(%Plug.Conn{assigns: %{route: route}} = conn, _args) do
    direction_id = 0 # Always use the outbound direction
    shapes = Routes.Repo.get_shapes(route.id, direction_id)
    route_stops = get_route_stops(shapes, route, direction_id)

    conn
    |> assign(:stop_list_template, "_stop_list.html")
    |> assign(:stops, route_stops)
    |> assign(:map_img_src, map_img_src(Enum.map(route_stops, & &1.station_info), route.type, route.id, shapes))
  end

  defp get_route_stops(shapes, route, direction_id) do
    route.id
    |> Stops.Repo.by_route(direction_id)
    |> Stops.RouteStops.by_direction(shapes, route, direction_id)
    |> Enum.flat_map(& &1.stops)
  end

  defp get_shape(shapes, variant) do
    shapes
    |> get_requested_shape(variant)
    |> get_default_shape(shapes)
  end

  defp get_requested_shape(_shapes, nil), do: nil
  defp get_requested_shape(shapes, variant), do: Enum.find(shapes, &(&1.id == variant))

  defp get_default_shape(nil, [default | _]), do: default
  defp get_default_shape(shape, _shapes), do: shape

  @doc """

  Stop features are a list of atoms for icons at a given stop.  We ignore the
  feature we're currently display, since by definition all the stops would
  have that feature.

  """
  @spec stop_features([Stops.Stop.t], Routes.Route.t) :: %{Stops.Stop.id_t => [atom]}
  def stop_features(stops, route) do
    stops
    |> Task.async_stream(&do_stop_features(&1, route))
    |> Map.new(fn {:ok, key_value} -> key_value end)
  end

  defp do_stop_features(stop, route) do
    route_feature = Routes.Route.icon_atom(route)
    routes = stop.id
    |> Routes.Repo.by_stop
    |> Enum.map(&Routes.Route.icon_atom/1)
    |> Enum.reject(& &1 == route_feature)
    |> Enum.uniq()
    |> Enum.sort_by(&sort_routes_by_icon/1)

    accessibility = if "accessible" in stop.accessibility do
      [:access]
    else
      []
    end

    {stop.id, routes ++ accessibility}
  end

  defp sort_routes_by_icon(:commuter_rail), do: 0
  defp sort_routes_by_icon(:bus), do: 2
  defp sort_routes_by_icon(_), do: 1

  @doc """

  Returns an image to display on the right/bottom part of the page.  For CR,
  and bus, we display a Google Map with the stops.  For others, we display a spider
  map.

  """
  @spec map_img_src([Stops.Stop.t], 0..4, String.t, [Routes.Shape.t] | [nil]) :: String.t
  def map_img_src(_, 4, _, _) do
    static_url(Site.Endpoint, "/images/ferry-spider.jpg")
  end
  def map_img_src(_, _, _, [nil]) do
    ""
  end
  def map_img_src(stops, route_type, route_id, shapes) do
    paths = shapes
    |> Enum.map(& &1.polyline)
    |> PolylineHelpers.condense
    |> Enum.map(&{:path, "color:0x#{map_color(route_type, route_id)}FF|enc:#{&1}"})

    opts = paths ++ [
      markers: markers(stops, route_type, route_id)
    ]

    GoogleMaps.static_map_url(600, 600, opts)
  end

  @spec map_color(String.t, String.t) :: String.t
  defp map_color(3, _id), do: "FFCE0C"
  defp map_color(2, _id), do: "A00A78"
  defp map_color(_type, "Blue"), do: "0064C8"
  defp map_color(_type, "Red"), do: "FF1428"
  defp map_color(_type, "Mattapan"), do: "FF1428"
  defp map_color(_type, "Orange"), do: "FF8200"
  defp map_color(_type, "Green"), do: "428608"
  defp map_color(_type, _id), do: "0064C8"

  defp markers(stops, type, id) do
    ["anchor:center",
     "icon:#{icon_path(type, id)}",
     path(stops)]
    |> Enum.join("|")
  end

  defp path(stops) do
    stops
    |> Enum.map(&position_string/1)
    |> Enum.join("|")
  end

  defp position_string(%{latitude: latitude, longitude: longitude}) do
    "#{Float.floor(latitude, 4)},#{Float.floor(longitude, 4)}"
  end

  defp icon_path(type, id) do
    static_url(Site.Endpoint, "/images/map-#{map_color(type, id)}-dot-icon.png")
  end

  @doc """

  Builds %{stop_id => active_map}.  active map is
  %{route_id => nil | :empty | :line | :stop | :eastbound_terminus | :westbound_terminus}.
  :empty means we should take up space for that route, but not display anything
  :line means we should display a line
  :stop means we should display a bordered bubble with the route letter
  :westbound_terminus and :eastbound_terminus mean we should display a filled
    bubble with the route letter. Westbound terminals get styled a bit differently due to
    the details of the stop bubble display.
  nil (not present) means we shouldn't take up space for that route

  """
  def active_lines(stops_on_routes) do
    {map, _} = stops_on_routes
    |> GreenLine.all_stops
    |> Enum.reverse
    |> Enum.reduce({%{}, %{}}, &do_active_line(&1, &2, stops_on_routes))
    map
  end

  defp do_active_line(stop, {map, currently_active}, stops_on_routes) do
    currently_active = update_active(stop.id, currently_active, stops_on_routes)
    map = put_in map[stop.id], currently_active
    {map, currently_active}
  end

  defp update_active(stop_id, currently_active, stops_on_routes) do
    GreenLine.branch_ids()
    |> Enum.reduce(currently_active, fn route_id, currently_active ->
      if GreenLine.stop_on_route?(stop_id, route_id, stops_on_routes) do
        stop_or_terminus = cond do
          GreenLine.terminus?(stop_id, route_id, 0) -> :westbound_terminus
          GreenLine.terminus?(stop_id, route_id, 1) -> :eastbound_terminus
          true -> :stop
        end
        put_in currently_active[route_id], stop_or_terminus
      else
        case Map.get(currently_active, route_id) do
          nil ->
            # don't add an entry if we don't have one already
            currently_active
          current_value ->
            put_in currently_active[route_id], update_active_line(current_value)
        end
      end
    end)
  end

  defp update_active_line(:empty), do: :empty
  defp update_active_line(:westbound_terminus), do: :empty
  defp update_active_line(:eastbound_terminus), do: :empty
  defp update_active_line(_), do: :line

  defp green_line_branches(stops, stop_map, expanded) do
    Enum.reject(stops, & do_green_line_branches(&1.id, stop_map[&1.id], expanded))
  end

  defp do_green_line_branches(stop_id, [route_id], expanded) do
    route_id != expanded and not GreenLine.terminus?(stop_id, route_id)
  end
  defp do_green_line_branches(_stop_id, _routes, _expanded), do: false

  defp insert_expands(stops, active_lines) do
    stops
    |> Enum.flat_map(
      & case expand_route_pair(&1.id, active_lines) do
          false -> [&1]
          expand_pair -> [expand_pair, &1]
        end
    )
  end

  defp expand_route_pair(stop_id, active_lines) do
    Enum.reduce(
      GreenLine.branch_ids(),
      false,
      fn (route_id, acc) ->
        if active_lines[stop_id][route_id] == :westbound_terminus do
          {:expand, stop_id, route_id}
        else
          acc
        end
      end)
  end
end
