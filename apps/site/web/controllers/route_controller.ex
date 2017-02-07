defmodule Site.RouteController do
  use Site.Web, :controller

  plug Site.Plugs.Route

  def show(conn, %{"route" => "Green"}) do
    route = %Routes.Route{id: "Green", type: 0}
    {stops, stop_route_id_set} = GreenLine.stops_on_routes()

    render conn, "show.html",
      stop_list_template: "_stop_list_green.html",
      stops: stops,
      active_lines: active_lines(stops, stop_route_id_set),
      stop_features: stop_features(stops, route),
      map_img_src: map_img_src(stops, route.type)
  end
  def show(conn, %{"route" => "Red"}) do
    stops = Stops.Repo.by_route("Red", 0)
    {ashmont, braintree} = Enum.split_while(stops, & &1.id != "place-nqncy")
    render conn, "show.html",
      stop_list_template: "_stop_list_red.html",
      stops: ashmont,
      merge_stop_id: "place-jfk",
      braintree_branch_stops: braintree,
      stop_features: stop_features(stops, conn.assigns.route),
      map_img_src: map_img_src(stops, conn.assigns.route.type)
  end
  def show(%Plug.Conn{assigns: %{route: nil}} = conn, _params) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
    |> halt
  end
  def show(conn, %{"route" => route_id}) do
    stops = Stops.Repo.by_route(route_id, 1)
    render conn, "show.html",
      stop_list_template: "_stop_list.html",
      stops: stops,
      stop_features: stop_features(stops, conn.assigns.route),
      map_img_src: map_img_src(stops, conn.assigns.route.type)
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

  Returns the current full list of stops on the Green line, along with a
  MapSet for all {stop_id, route_id} pairs where that stop in on that route.

  """
  # the {:ok, _} part of the pattern match is due to using Task.async_stream.
  def merge_green_line_stops({:ok, {route_id, line_stops}}, {current_stops, stop_route_id_set}) do
    # update stop_route_id_set to tag the routes the stop is one
    stop_route_id_set = line_stops
    |> Enum.reduce(stop_route_id_set, fn %{id: stop_id}, set ->
      MapSet.put(set, {stop_id, route_id})
    end)

    current_stops = line_stops
    |> List.myers_difference(current_stops)
    |> Enum.flat_map(fn {_op, stops} -> stops end)

    {current_stops, stop_route_id_set}
  end

  @doc """

  Builds %{stop_id => active_map}.  active map is %{route_id => nil | :empty | :line | :stop | :terminus}
  :empty means we should take up space for that route, but not display anything
  :line means we should display a line
  :stop means we should display a bordered bubble with the route letter
  :terminus means we should display a filled bubble with the route letter
  nil (not present) means we shouldn't take up space for that route

  """
  def active_lines(stops, stop_route_id_set) do
    {map, _} = stops
    |> Enum.reverse
    |> Enum.reduce({%{}, %{}}, &do_active_line(&1, &2, stop_route_id_set))
    map
  end

  defp do_active_line(stop, {map, currently_active}, stop_route_id_set) do
    currently_active = update_active(stop.id, currently_active, stop_route_id_set)
    map = put_in map[stop.id], currently_active
    {map, currently_active}
  end

  defp update_active(stop_id, currently_active, stop_route_id_set) do
    ~w(Green-B Green-C Green-D Green-E)s
    |> Enum.reduce(currently_active, fn route_id, currently_active ->
      if MapSet.member?(stop_route_id_set, {stop_id, route_id}) do
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
end
