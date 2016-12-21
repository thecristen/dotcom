defmodule Site.Plugs.TransitNearMe do
  import Plug.Conn
  import Phoenix.Controller, [only: [put_flash: 3]]
  alias GoogleMaps.Geocode
  alias Routes.Route
  alias Stops.{Stop, Distance}

  defmodule Options do
    defstruct [
      nearby_fn: &Stops.Nearby.nearby/1,
      routes_by_stop_fn: &Routes.Repo.by_stop/1
    ]
  end

  def init([]), do: %Options{}

  def call(%{assigns: %{stops_with_routes: stops_with_routes}} = conn, _options) when is_list(stops_with_routes) do
    conn
    |> flash_if_error()
  end
  def call(%{params: %{"location" => %{"address" => address}}} = conn, options) do
    location = address
    |> GoogleMaps.Geocode.geocode

    stops_with_routes = calculate_stops_with_routes(location, options)

    do_call(conn, stops_with_routes, location)
  end
  # Used in Backstop tests to avoid calling Google Maps
  def call(%{params: %{"latitude" => latitude, "longitude" => longitude}} = conn, options) do
    formatted = conn.params
    |> Map.get("location", %{})
    |> Map.get("address", "#{latitude}, #{longitude}")

    location = {:ok, [
        %Geocode.Address{
          latitude: String.to_float(latitude),
          longitude: String.to_float(longitude),
          formatted: formatted
        }
      ]
    }

    stops_with_routes = calculate_stops_with_routes(location, options)

    do_call(conn, stops_with_routes, location)
  end
  def call(conn, _options) do
    do_call(conn, [], "")
  end

  defp do_call(conn, stops_with_routes, address) do
    conn
    |> assign(:stops_with_routes, stops_with_routes)
    |> assign_address(address)
    |> flash_if_error()
  end

  #TODO handle differently when multiple results are returned?
  @doc """
    Retrieves stops close to a location and parses into the correct configuration
  """
  @spec get_stops_nearby(GoogleMaps.Geocode.t, Plug.Conn.t) :: [Stop.t]
  def get_stops_nearby({:ok, [location | _]}, nearby_fn) do
    nearby_fn.(location)
  end
  def get_stops_nearby({:error, _error_code, _error_str}, _nearby_fn) do
    []
  end

  @spec stops_with_routes([Stop.t], Geocode.t, ((String.t) -> [Route.t])) :: [%{stop: Stop.t, distance: String.t, routes: [Routes.Group.t]}]
  def stops_with_routes(stops, {:ok, [location|_]}, routes_by_stop_fn) do
    stops
    |> Enum.map(fn stop ->
      %{stop: stop,
        distance: Distance.haversine(stop, location),
        routes: stop.id |> routes_by_stop_fn.() |> get_route_groups}
    end)
  end
  def stops_with_routes([], {:error, _, _}, _), do: []

  defp calculate_stops_with_routes(location, options) do
    location
    |> get_stops_nearby(options.nearby_fn)
    |> stops_with_routes(location, options.routes_by_stop_fn)
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

  @spec address(GoogleMaps.Geocode.t) :: String.t
  def address({:ok, [%{formatted: address} | _]}) do
    address
  end
  def address(_), do: ""

  def assign_address(conn, {:ok, [%{formatted: address} | _]}) do
    conn
    |> assign(:address, address)
  end
  def assign_address(conn, {:error, :zero_results, _}) do
    conn
    |> assign(:address, "")
    |> put_private(:error, "The address you've listed appears to be invalid. Please try a new address to continue.")
  end
  def assign_address(conn, {:error, _status, message}) do
    conn
    |> assign(:address, "")
    |> put_private(:error, message)
  end
  def assign_address(conn, _) do
    conn
    |> assign(:address, "")
  end

  @spec flash_if_error(Plug.Conn.t) :: Plug.Conn.t
  def flash_if_error(%Plug.Conn{assigns: %{stops_with_routes: [], address: address}} = conn) when address != "" do
    message = Phoenix.HTML.Tag.content_tag(:div,
      "There doesn't seem to be any stations found near the given address. Please try a different address to continue.",
      class: "error-message")

    put_flash(conn, :info, message)
  end
  def flash_if_error(%Plug.Conn{private: %{error: error}} = conn) when error != nil do
    message = Phoenix.HTML.Tag.content_tag(:div,
      error,
      class: "error-message")

    put_flash(conn, :info, message)
  end
  def flash_if_error(conn), do: conn
end
