defmodule Site.RouteController do
  use Site.Web, :controller

  plug Site.Plugs.Route

  def show(conn, %{"route" => "Green"}) do
  end
  def show(conn, %{"route" => "Red"}) do
  end
  def show(%Plug.Conn{assigns: %{route: nil}} = conn, _params) do
    conn
    |> put_status(:not_found)
    |> render(Site.ErrorView, "404.html", [])
    |> halt
  end
  def show(conn, %{"route" => route_id}) do
    stops = route_id
    |> Schedules.Repo.stops(direction_id: 1) # Inbound
    |> Task.async_stream(&Stops.Repo.get(&1.id))
    |> Enum.map(fn {:ok, stop} -> stop end)

    render conn, "show.html",
      stops: stops,
      stop_features: stop_features(stops, conn.assigns.route),
      map_img_src: map_img_src(stops)
  end

  def stop_features(stops, route) do
    Map.new(stops,
      fn stop ->
        {stop.id, do_stop_features(stop, route)}
      end)
  end

  defp do_stop_features(stop, route) do
    route_type_atom = Routes.Route.type_atom(route)
    routes = stop.id
    |> Routes.Repo.by_stop
    |> Enum.group_by(&Routes.Route.type_atom/1)
    # reject the current type of route
    |> Enum.reject(&match?({^route_type_atom, _}, &1))
    |> Enum.sort_by(&sort_routes_by_type/1)
    |> Enum.flat_map(&deaggregate_routes/1)

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
    |> Enum.map(&subway_route_feature/1)
    |> Enum.uniq
  end
  defp deaggregate_routes({other_type, _routes}) do
    [other_type]
  end

  defp subway_route_feature(%Routes.Route{id: "Red"}), do: :red_line
  defp subway_route_feature(%Routes.Route{id: "Orange"}), do: :orange_line
  defp subway_route_feature(%Routes.Route{id: "Blue"}), do: :blue_line
  defp subway_route_feature(%Routes.Route{id: "Green-" <> _}), do: :green_line

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
end
