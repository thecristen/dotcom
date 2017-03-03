defmodule Site.RouteController do
  use Site.Web, :controller

  plug Site.Plugs.Route
  plug Site.Plugs.Date
  plug :hours_of_operation
  plug :next_3_holidays

  def show(conn, %{"route" => "Green"} = params) do
    route = GreenLine.green_line()
    stops_on_routes = GreenLine.stops_on_routes(0)
    routes_for_stops = GreenLine.routes_for_stops(stops_on_routes) # Inverse Map
    stops = GreenLine.all_stops(stops_on_routes)
    {before_branch, after_branch} = Enum.split_while(stops, & &1.id != "place-coecl")
    expanded = params["expanded"]
    expanded_stops = green_line_branches(after_branch, routes_for_stops, expanded)

    conn
    |> render("show.html",
      stop_list_template: "_stop_list_green.html",
      stops: before_branch ++ expanded_stops,
      expanded: expanded,
      active_lines: active_lines(stops_on_routes),
      stop_features: stop_features(stops, route),
      map_img_src: map_img_src(stops, route.type),
      route: route)
  end
  def show(conn, %{"route" => "Red"} = params) do
    stops = Stops.Repo.by_route("Red", 0)
    {shared_stops, branched_stops} = Enum.split_while(stops, & &1.id != "place-shmnl")
    {ashmont, braintree} = red_line_branches(branched_stops, params)

    conn
    |> render("show.html",
      stop_list_template: "_stop_list_red.html",
      stops: shared_stops,
      merge_stop_id: "place-jfk",
      braintree_branch_stops: braintree,
      ashmont_branch_stops: ashmont,
      stop_features: stop_features(stops, conn.assigns.route),
      map_img_src: map_img_src(stops, conn.assigns.route.type))
  end
  def show(%Plug.Conn{assigns: %{route: nil}} = conn, _params) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
    |> halt
  end
  def show(conn, %{"route" => "CR-"<>_ = route_id}) do
    stops = Stops.Repo.by_route(route_id, 1)

    zones = Enum.reduce stops, %{}, fn stop, acc ->
      Map.put(acc, stop.id, Zones.Repo.get(stop.id))
    end

    render conn, "show.html",
      stop_list_template: "_stop_list.html",
      stops: stops,
      stop_features: stop_features(stops, conn.assigns.route),
      map_img_src: map_img_src(stops, conn.assigns.route.type),
      zones: zones
  end
  def show(conn, %{"route" => route_id}) do
    stops = Stops.Repo.by_route(route_id, 1)
    conn
    |> render("show.html",
      stop_list_template: "_stop_list.html",
      stops: stops,
      stop_features: stop_features(stops, conn.assigns.route),
      map_img_src: map_img_src(stops, conn.assigns.route.type))
  end

  def hours_of_operation(%Plug.Conn{assigns: %{route: route}, params: %{"route" => route_id}} = conn, opts)
  when (not is_nil(route)) or (route_id == "Green") do
    dates = get_dates(conn.assigns.date)
    schedules_fn = schedules_fn(opts)
    assign(conn, :hours_of_operation, %{
          :week => get_hours(conn, dates[:week], schedules_fn),
          :saturday => get_hours(conn, dates[:saturday], schedules_fn),
          :sunday => get_hours(conn, dates[:sunday], schedules_fn)}
    )
  end
  def hours_of_operation(conn, _opts) do
    conn
  end

  defp get_hours(%Plug.Conn{params: %{"route" => "Green"}}, date, schedules_fn) do
    do_get_hours(Enum.join(GreenLine.branch_ids(), ","), date, schedules_fn)
  end
  defp get_hours(%Plug.Conn{assigns: %{route: route}}, date, schedules_fn) do
    do_get_hours(route.id, date, schedules_fn)
  end

  defp do_get_hours(route_id, date, schedules_fn) do
    {inbound, outbound} = [date: date, stop_sequence: "first,last"]
    |> Keyword.merge(route: route_id)
    |> schedules_fn.()
    |> Enum.split_with(& &1.trip.direction_id == 1)

    %{
      1 => Schedules.Departures.first_and_last_departures(inbound),
      0 => Schedules.Departures.first_and_last_departures(outbound)
    }
  end

  defp get_dates(date) do
    %{
      :week => Timex.end_of_week(date, 2),
      :saturday => Timex.end_of_week(date, 7),
      :sunday => Timex.end_of_week(date, 1)
    }
  end

  defp schedules_fn(opts) do
    Keyword.get(opts, :schedules_fn, &Schedules.Repo.all/1)
  end

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
  we display a Google Map with the stops.  For others, we display a spider
  map.

  """
  @spec map_img_src([Stops.Stop.t], 0..4) :: String.t
  def map_img_src(stops, route_type)
  def map_img_src(_, type) when type in [0, 1, 3] do # subway or bus
    static_url(Site.Endpoint, "/images/subway-spider.jpg")
  end
  def map_img_src(stops, 2) do
    opts = [
      markers: markers(stops),
      path: path(stops)
    ]
    GoogleMaps.static_map_url(500, 500, opts)
  end
  def map_img_src(_, 4) do # ferry
    static_url(Site.Endpoint, "/images/ferry-spider.jpg")
  end

  defp markers(stops) do
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
    "#{latitude},#{longitude}"
  end

  defp icon_path() do
    static_url(Site.Endpoint, "/images/mbta-logo-t-favicon.png")
  end

  @doc """

  Builds %{stop_id => active_map}.  active map is %{route_id => nil | :empty | :line | :stop | :terminus}
  :empty means we should take up space for that route, but not display anything
  :line means we should display a line
  :stop means we should display a bordered bubble with the route letter
  :terminus means we should display a filled bubble with the route letter
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
        stop_or_terminus = if GreenLine.terminus?(stop_id, route_id), do: :terminus, else: :stop
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
  defp update_active_line(:terminus), do: :empty
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

  def next_3_holidays(%Plug.Conn{assigns: %{date: date}} = conn, _opts) do
    holidays = date
    |> Holiday.Repo.following
    |> Enum.take(3)

    conn
    |> assign(:holidays, holidays)
  end
  def next_3_holidays(conn, _opts) do
    conn
  end
end
