defmodule Site.RouteController do
  use Site.Web, :controller

  plug Site.Plugs.Route

  def show(conn, %{"route" => "Green"}) do
    {stops, stop_route_id_map} = ~w(Green-B Green-C Green-D Green-E)s
    |> Task.async_stream(&green_line_stops/1)
    |> Enum.reduce({[], %{}}, &merge_green_line_stops/2)

    render conn, "show.html",
      stop_list_template: "_stop_list_green.html",
      stops: stops,
      active_lines: active_lines(stops, stop_route_id_map),
      stop_features: stop_features(stops, %Routes.Route{id: "Green", type: 0}),
      map_img_src: static_url(conn, "/images/subway-spider.jpg")
  end
  def show(conn, %{"route" => "Red"}) do
    stops = stops("Red", 0)
    {ashmont, braintree} = split_at(stops, "place-nqncy")
    render conn, "show.html",
      stop_list_template: "_stop_list_red.html",
      stops: ashmont,
      merge_stop_id: "place-jfk",
      braintree_branch_stops: braintree,
      stop_features: stop_features(stops, conn.assigns.route),
      map_img_src: static_url(conn, "/images/subway-spider.jpg")
  end
  def show(%Plug.Conn{assigns: %{route: nil}} = conn, _params) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
    |> halt
  end
  def show(conn, %{"route" => route_id}) do
    stops = stops(route_id, 1)
    render conn, "show.html",
      stop_list_template: "_stop_list.html",
      stops: stops,
      stop_features: stop_features(stops, conn.assigns.route),
      map_img_src: map_img_src(stops)
  end

  def stops(route_id, direction_id) do
    route_id
    |> Schedules.Repo.stops(direction_id: direction_id) # Inbound
    |> Task.async_stream(&Stops.Repo.get(&1.id))
    |> Enum.map(fn {:ok, stop} -> stop end)
  end

  def stop_features(stops, route) do
    Map.new(stops,
      fn stop ->
        {stop.id, do_stop_features(stop, route)}
      end)
  end

  defp do_stop_features(stop, route) do
    route_feature = route_feature(route)
    routes = stop.id
    |> Routes.Repo.by_stop
    |> Enum.group_by(&Routes.Route.type_atom/1)
    |> Enum.sort_by(&sort_routes_by_type/1)
    |> Enum.flat_map(&deaggregate_routes/1)
    |> Enum.reject(& &1 == route_feature)
    accessibility = if "accessible" in stop.accessibility do
      [:access]
    else
      []
    end

    routes ++ accessibility
  end

  defp sort_routes_by_type({:commuter_rail, _}), do: 0
  defp sort_routes_by_type({:subway, _}), do: 1
  defp sort_routes_by_type({:bus, _}), do: 2
  defp sort_routes_by_type({_, _}), do: 3

  defp deaggregate_routes({:subway, routes}) do
    routes
    |> Enum.map(&route_feature/1)
    |> Enum.uniq
  end
  defp deaggregate_routes({other_type, _routes}) do
    [other_type]
  end

  defp route_feature(%Routes.Route{id: "Red"}), do: :red_line
  defp route_feature(%Routes.Route{id: "Orange"}), do: :orange_line
  defp route_feature(%Routes.Route{id: "Blue"}), do: :blue_line
  defp route_feature(%Routes.Route{id: "Green" <> _}), do: :green_line
  defp route_feature(%Routes.Route{} = route), do: Routes.Route.type_atom(route)

  def map_img_src(stops) do
    opts = [
      markers: markers(stops),
      path: path(stops)
    ]
    GoogleMaps.static_map_url(500, 500, opts)
  end

  defp markers(stops) do
    ["anchor:center",
     "icon:#{icon_path()}",
     path(stops)]
    |> Enum.join("|")
  end

  defp path(stops) do
    stops
    |> Enum.map(&position/1)
    |> Enum.join("|")
  end

  defp position(%{latitude: latitude, longitude: longitude}) do
    "#{latitude},#{longitude}"
  end

  def icon_path() do
    static_url(Site.Endpoint, "/images/mbta-logo-t-favicon.png")
  end

  # splits the stop list into two, where the first stop in the second list is stop_id
  defp split_at(stops, stop_id) do
    do_split_at(stops, stop_id, [])
  end

  defp do_split_at([%{id: stop_id}| _] = stops, stop_id, acc) do
    {Enum.reverse(acc), stops}
  end
  defp do_split_at([stop | rest], stop_id, acc) do
    do_split_at(rest, stop_id, [stop | acc])
  end

  defp green_line_stops(route_id) do
    {route_id, route_id
    |> stops(0)
    |> green_line_filter(route_id)}
  end

  defp green_line_filter(stops, "Green-B") do
    stops
    |> Enum.drop_while(& &1.id != "place-pktrm")
  end
  defp green_line_filter(stops, "Green-C") do
    stops
    |> Enum.drop_while(& &1.id != "place-north")
  end
  defp green_line_filter(stops, "Green-D") do
    stops
    |> Enum.drop_while(& &1.id != "place-gover")
  end
  defp green_line_filter(stops, "Green-E") do
    stops
  end

  defp merge_green_line_stops({:ok, {route_id, line_stops}}, {current_stops, stop_route_id_map}) do
    # update stop_route_id_map to tag the routes the stop is one
    stop_route_id_map = line_stops
    |> Enum.reduce(stop_route_id_map, fn %{id: stop_id}, map ->
      put_in map[{stop_id, route_id}], true
    end)

    current_stops = line_stops
    |> List.myers_difference(current_stops)
    |> Enum.flat_map(fn {_op, stops} -> stops end)

    {current_stops, stop_route_id_map}
  end

  # Builds %{stop_id => active_map}.  active map is %{route_id => nil | :line | :stop | :terminus}
  # nil means we should take up space for that route, but not display anything
  # :line means we should display a line
  # :stop means we should display a bordered bubble with the route letter
  # :terminus means we should display a filled bubble with the route letter
  defp active_lines(stops, stop_route_id_map) do
    {map, _} = stops
    |> Enum.reverse
    |> Enum.reduce({%{}, %{}}, &do_active_line(&1, &2, stop_route_id_map))
    map
  end

  defp do_active_line(stop, {map, currently_active}, stop_route_id_map) do
    currently_active = update_active(stop.id, currently_active, stop_route_id_map)
    map = put_in map[stop.id], currently_active
    {map, currently_active}
  end

  defp update_active(stop_id, currently_active, stop_route_id_map) do
    ~w(Green-B Green-C Green-D Green-E)s
    |> Enum.reduce(currently_active, fn route_id, currently_active ->
      if stop_route_id_map[{stop_id, route_id}] do
        stop_or_terminus = stop_or_terminus(stop_id, route_id)
        put_in currently_active[route_id], stop_or_terminus
      else
        case Map.fetch(currently_active, route_id) do
          :error ->
            # don't add an entry if we don't have one already
            currently_active
          {:ok, current_value} ->
            put_in currently_active[route_id], update_active_line(current_value)
        end
      end
    end)
  end

  defp stop_or_terminus(stop_id, "Green-B") when stop_id in ["place-lake", "place-pktrm"] do
    :terminus
  end
  defp stop_or_terminus(stop_id, "Green-C") when stop_id in ["place-north", "place-clmnl"] do
    :terminus
  end
  defp stop_or_terminus(stop_id, "Green-D") when stop_id in ["place-river", "place-gover"] do
    :terminus
  end
  defp stop_or_terminus(stop_id, "Green-E") when stop_id in ["place-lech", "place-hsmnl"] do
    :terminus
  end
  defp stop_or_terminus(_, _) do
    :stop
  end

  defp update_active_line(:empty), do: :empty
  defp update_active_line(:terminus), do: :empty
  defp update_active_line(_), do: :line
end
