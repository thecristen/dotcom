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
    |> get_shapes(conn.assigns.direction_id)

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
    |> assign(:map_img_src, map_img_src(conn.assigns.all_stops, route.type, shapes))
    |> assign(:route, route)
  end
  def call(%Plug.Conn{assigns: %{route: %{id: "Red"}}} = conn, _args) do
    stops = Stops.Repo.by_route("Red", 0)
    shapes = get_shapes("Red", conn.assigns.direction_id)
    {shared_stops, branched_stops} = Enum.split_while(stops, & &1.id != "place-shmnl")
    {ashmont, braintree} = red_line_branches(branched_stops, conn.params)

    conn
    |> assign(:stop_list_template, "_stop_list_red.html")
    |> assign(:stops, shared_stops)
    |> assign(:merge_stop_id, "place-jfk")
    |> assign(:braintree_branch_stops, braintree)
    |> assign(:ashmont_branch_stops, ashmont)
    |> assign(:stop_features, stop_features(stops, conn.assigns.route))
    |> assign(:map_img_src, map_img_src(conn.assigns.all_stops, conn.assigns.route.type, shapes))
  end
  def call(%Plug.Conn{assigns: %{route: %{id: "CR-"<>_ = route_id}}} = conn, _args) do
    stops = Stops.Repo.by_route(route_id, 1)
    shapes = get_shapes(route_id, conn.assigns.direction_id)

    zones = Enum.reduce stops, %{}, fn stop, acc ->
      Map.put(acc, stop.id, Zones.Repo.get(stop.id))
    end

    conn
    |> assign(:stops, stops)
    |> assign(:stop_features, stop_features(stops, conn.assigns.route))
    |> assign(:map_img_src, map_img_src(conn.assigns.all_stops, conn.assigns.route.type, shapes))
    |> assign(:zones, zones)
    |> assign(:stop_list_template, "_stop_list.html")
  end
  def call(%Plug.Conn{assigns: %{route: %{id: route_id, type: 3}}} = conn, _args) do
    # in the case of buses, get the stops from the selected/default shape
    shapes = get_shapes(route_id, conn.assigns.direction_id)

    active_shape = get_shape(shapes, conn.query_params["variant"])
    stops = get_stops_from_shape(active_shape)
    show_variant_selector = case shapes do
      [_, _ | _] -> true
      _ -> false
    end

    conn
    |> assign(:stop_list_template, "_stop_list.html")
    |> assign(:stops, stops)
    |> assign(:shapes, shapes)
    |> assign(:active_shape, active_shape)
    |> assign(:show_variant_selector, show_variant_selector)
    |> assign(:stop_features, stop_features(stops, conn.assigns.route))
    |> assign(:map_img_src, map_img_src(stops, conn.assigns.route.type, [active_shape]))
  end
  def call(%Plug.Conn{assigns: %{route: %{id: route_id}}} = conn, _args) do
    stops = Stops.Repo.by_route(route_id, 1)
    shapes = get_shapes(route_id, conn.assigns.direction_id)

    conn
    |> assign(:stop_list_template, "_stop_list.html")
    |> assign(:stops, stops)
    |> assign(:stop_features, stop_features(stops, conn.assigns.route))
    |> assign(:map_img_src, map_img_src(conn.assigns.all_stops, conn.assigns.route.type, shapes))
  end

  defp get_shapes(route_id, direction_id) do
    Routes.Repo.get_shapes(route_id, direction_id)
  end

  defp get_shape(shapes, variant) do
    shapes
    |> get_requested_shape(variant)
    |> get_default_shape(shapes)
  end

  defp get_stops_from_shape(%{stop_ids: stop_ids}) do
    stop_ids
    |> Task.async_stream(& Stops.Repo.get(&1))
    |> Enum.map(fn {:ok, stop} -> stop end)
  end
  defp get_stops_from_shape(_) do
    []
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
  @spec map_img_src([Stops.Stop.t], 0..4, [Routes.Shape.t] | [nil]) :: String.t
  def map_img_src(_, 4, _) do
    static_url(Site.Endpoint, "/images/ferry-spider.jpg")
  end
  def map_img_src(_, _, [nil]) do
    ""
  end
  def map_img_src(stops, route_type, shapes) do
    paths = shapes
    |> Enum.map(& &1.polyline)
    |> PolylineHelpers.condense
    |> Enum.map(&{:path, "enc:#{&1}"})

    opts = paths ++ [
      markers: markers(stops, route_type)
    ]

    GoogleMaps.static_map_url(600, 600, opts)
  end

  defp markers(stops, 3) do
    ["anchor:center",
     path(stops)]
    |> Enum.join("|")
  end
  defp markers(stops, _type) do
    ["anchor:center",
     "icon:#{icon_path()}",
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

  defp icon_path() do
    static_url(Site.Endpoint, "/images/map_red_dot_icon.png")
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

  defp red_line_branches(stops, %{"expanded" => "braintree"}) do
    {ashmont, braintree} = split_ashmont_braintree(stops)
    {[List.last(ashmont)], braintree}
  end
  defp red_line_branches(stops, %{"expanded" => "ashmont"}) do
    {Enum.take_while(stops, & &1.id != "place-nqncy"), [List.last(stops)]}
  end
  defp red_line_branches(stops, _params) do
    {ashmont, braintree} = split_ashmont_braintree(stops)
    {[List.last(ashmont)], [List.last(braintree)]}
  end

  defp split_ashmont_braintree(stops) do
    Enum.split_while(stops, & &1.id != "place-nqncy")
  end

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
