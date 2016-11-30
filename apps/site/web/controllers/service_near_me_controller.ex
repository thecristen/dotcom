defmodule Site.ServiceNearMeController do
  use Site.Web, :controller
  alias Routes.Route

  @doc """
    Handles GET requests both with and without parameters. Calling with an address parameter (String.t) will assign
    make available to the view:
        @stops_with_routes :: [%{stop: %Stops.Stop{}, routes: [%Route{}]}]
  """
  def index(conn, %{"location" => %{"address" => address}}) do
    address
    |> call_google_api
    |> get_stops_nearby(conn)
    |> send_response(conn, address)
  end
  def index(conn, _) do
    send_response([], conn)
  end


  @spec call_google_api(String.t) :: {:ok, GoogleMaps.t} | {:error, :invalid | {:invalid, String.t}}
  def call_google_api(address) do
    maps_request_url
    |> HTTPoison.get([], params: %{address: address, key: Site.ViewHelpers.google_api_key })
    |> parse_results
  end


  @spec parse_results({:ok, HTTPoison.Response.t} | {:error, any}) :: {:ok, GoogleMaps.t} | {:error, :invalid | {:invalid, String.t}}
  defp parse_results({:error, error}), do: throw error
  defp parse_results({:ok, %HTTPoison.Response{body: response_body}}) do
    response_body
    |> Poison.Parser.parse
  end


  #TODO handle differently when multiple results are returned?
  @doc """
    Retrieves stops close to a location and parses into the correct configuration
  """
  @spec get_stops_nearby({:ok, GoogleMaps.t} | {:error, {:invalid, String.t}}, Plug.Conn.t) :: [%{stop: Stops.Stop.t, routes: [Routes.Group.t]}]
  def get_stops_nearby({:ok, %{"results" => [ %{"geometry" => %{"location" => %{"lat" => lat, "lng" => lng}}} | _]}},
                       %{private: private}) do
    private
    |> Map.get(:nearby_stops, &Stops.Nearby.nearby/1)
    |> Kernel.apply([{lat, lng}])
    |> Enum.map(fn stop -> {stop, Routes.Repo.by_stop(stop.id)} end)
    |> Enum.map(fn {stop, route_list} -> %{stop: stop, routes: get_route_groups(route_list)} end)
  end
  def get_stops_nearby({:ok, %{"results" => [], "status" => "ZERO_RESULTS"}}, _), do: []
  def get_stops_nearby({:error, error}), do: throw error


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
    # |> Keyword.delete(:subway)
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


  @spec send_response([%{stop: Stops.Stop.t, routes: [Routes.Group.t]}], Plug.Conn.t, String.t) :: Plug.Conn.t
  defp send_response(stops_with_routes, conn, address \\ "") do
    conn
    |> assign(:stops_with_routes, stops_with_routes)
    |> assign(:address, address)
    |> render("index.html", breadcrumbs: ["Service Near Me"])
  end


  defp base_url do
    "https://maps.googleapis.com"
  end

  defp maps_request_url do
    base_url <> "/maps/api/geocode/json"
  end
end
