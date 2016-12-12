defmodule Site.Plugs.ServiceNearMe do
  import Plug.Conn
  alias Routes.Route
  alias Stops.Stop

  defmodule Options do
    defstruct [
      nearby_fn: &Stops.Nearby.nearby/1,
      routes_by_stop_fn: &Routes.Repo.by_stop/1
    ]
  end

  def init([]), do: %Options{}

  def call(%{params: %{"location" => %{"address" => address}}} = conn, options) do
    results = address
              |> GoogleMaps.Geocode.geocode

    nearby_fn = options.nearby_fn

    stops_with_routes = results
    |> get_stops_nearby(nearby_fn)
    |> stops_with_routes(options.routes_by_stop_fn)

    address = address(results)

    conn
    |> assign_stops_with_routes(stops_with_routes)
    |> assign_address(address)
  end
  def call(conn, _options) do
    conn
    |> assign_stops_with_routes([])
    |> assign_address("")
  end

  #TODO handle differently when multiple results are returned?
  @doc """
    Retrieves stops close to a location and parses into the correct configuration
  """
  @spec get_stops_nearby(GoogleMaps.Geocode.t, Plug.Conn.t) :: [Stop.t]
  #def get_stops_nearby({:ok, [location | _]},
  #                     %{private: private}) do
  #  private
  #  |> Map.get(:nearby_stops, &Stops.Nearby.nearby/1)
  #  |> Kernel.apply([location])
  #end
  #def get_stops_nearby({:ok, []}, _conn), do: []
  #def get_stops_nearby({:error, _error_code, _error_str}, _conn), do: []

  def get_stops_nearby({:ok, [location | _]}, nearby_fn) do
    nearby_fn.(location)
  end
  def get_stops_nearby({:error, _error_code, _error_str}, _nearby_fn) do
    []
  end


  @spec stops_with_routes([Stop.t], ((String.t) -> [Route.t])) :: [%{stop: Stop.t, routes: [Route.Group.t]}]
  def stops_with_routes(stops, routes_by_stop_fn) do
    stops
    |> Enum.map(fn stop ->
      %{stop: stop, routes: stop.id |> routes_by_stop_fn.() |> get_route_groups}
    end)
  end

  def assign_stops_with_routes(conn, stops_with_routes) do
    conn
    |> assign(:stops_with_routes, stops_with_routes)
  end

  def assign_address(conn, address) do
    conn
    |> assign(:address, address)
  end

  @spec get_route_groups([Route.t]) :: [Routes.Group.t]
  def get_route_groups(route_list) do
    route_list
    |> Routes.Group.group
    |> separate_subway_lines
    |> Keyword.delete(:subway)
  end


  @doc """
    Returns the grouped routes list with subway lines elevated to the top level, eg:

      separate_subway_lines([commuter: [_], bus: [_], subway: [orange_line, red_line])
      # =>   [commuter: [commuter_lines], bus: [bus_lines], orange: [orange_line], red: [red_line]]

  """
  @spec separate_subway_lines([Routes.Group.t]) :: [{Routes.Route.gtfs_route_type | Route.subway_lines_type, [Route.t]}]
  def separate_subway_lines([{:subway, subway_lines}|_] = routes) do
    subway_lines
    |> Enum.reduce(routes, &subway_reducer/2)
  end
  def separate_subway_lines(routes), do: routes


  @spec subway_reducer(Route.t, [Routes.Group.t]) :: [{Routes.Route.subway_lines_type, [Route.t]}]
  defp subway_reducer(%Route{id: id, type: 1} = route, routes) do
    Keyword.put(routes, id |> Kernel.<>("_line") |> String.downcase |> String.to_atom, [route])
  end
  defp subway_reducer(%Route{name: "Green" <> _} = route, routes) do
    Keyword.put(routes, :green_line, [route])
  end
  defp subway_reducer(%Route{id: "Mattapan"} = route, routes) do
    Keyword.put(routes, :red_line, [route])
  end

  def address({:ok, [%{formatted: address} | _]}) do
    address
  end
  def address(_), do: ""
end
