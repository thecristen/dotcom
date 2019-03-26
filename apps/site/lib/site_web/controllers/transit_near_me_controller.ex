defmodule SiteWeb.TransitNearMeController do
  use SiteWeb, :controller
  alias Alerts.Repo
  alias GoogleMaps.{Geocode, MapData, MapData.Layers, MapData.Marker}
  alias Phoenix.HTML
  alias Plug.Conn
  alias Site.TransitNearMe
  alias SiteWeb.PartialView
  alias SiteWeb.PartialView.{FullscreenError}
  alias Stops.Stop

  alias SiteWeb.TransitNearMeController.{
    Location,
    StopsWithRoutes
  }

  def index(conn, _params) do
    conn
    |> assign(:requires_google_maps?, true)
    |> assign(:disable_turbolinks, true)
    |> assign_location()
    |> assign_stops_and_routes()
    |> assign_map_data()
    |> flash_if_error()
    |> render("index.html", breadcrumbs: [Breadcrumb.build("Transit Near Me")])
  end

  defp assign_location(conn) do
    location_fn = Map.get(conn.assigns, :location_fn, &Location.get/2)

    location = location_fn.(conn.params, [])

    assign(conn, :location, location)
  end

  defp assign_stops_and_routes(%{assigns: %{location: {:ok, [location | _]}}} = conn) do
    data_fn = Map.get(conn.assigns, :data_fn, &TransitNearMe.build/2)

    # only concerned with high priority alerts
    alerts = Repo.by_priority(conn.assigns.date_time, :high)

    data = data_fn.(location, date: conn.assigns.date, now: conn.assigns.date_time)

    do_assign_stops_and_routes(conn, data, location, alerts)
  end

  defp assign_stops_and_routes(conn), do: do_assign_stops_and_routes(conn, {:stops, []}, nil, nil)

  defp do_assign_stops_and_routes(conn, {:stops, []}, _, _) do
    conn
    |> assign(:stops_json, [])
    |> assign(:routes_json, [])
  end

  defp do_assign_stops_and_routes(conn, data, location, alerts) do
    to_json_fn = Map.get(conn.assigns, :to_json_fn, &TransitNearMe.schedules_for_routes/3)

    conn
    |> assign(:stops_json, StopsWithRoutes.stops_with_routes(data, location))
    |> assign(:routes_json, to_json_fn.(data, alerts, now: conn.assigns.date_time))
  end

  def assign_map_data(conn) do
    markers =
      conn.assigns.stops_json
      |> Enum.map(&build_stop_marker(&1))

    map_data =
      {630, 400}
      |> MapData.new(14)
      |> MapData.disable_map_type_controls()
      |> MapData.add_layers(%Layers{transit: true})
      |> MapData.add_markers(markers)
      |> add_location_marker(conn.assigns)

    assign(conn, :map_data, map_data)
  end

  def build_stop_marker(
        %{stop: %{stop: %Stop{id: id, latitude: latitude, longitude: longitude}}} = marker
      ) do
    Marker.new(
      latitude,
      longitude,
      id: id,
      icon: marker_for_routes(marker.routes),
      size: :large,
      tooltip: tooltip(marker)
    )
  end

  def build_stop_marker(marker) do
    Marker.new(
      marker.stop.latitude,
      marker.stop.longitude,
      id: marker.stop.id,
      icon: marker_for_routes(marker.routes),
      size: :large,
      tooltip: tooltip(marker)
    )
  end

  @doc """
  Use a stop marker for bus-only stops, station marker otherwise
  """
  @spec marker_for_routes([map]) :: String.t() | nil
  def marker_for_routes([]) do
    "map-stop-marker"
  end

  def marker_for_routes(routes) do
    if List.first(routes).group_name == :bus do
      "map-stop-marker"
    else
      "map-station-marker"
    end
  end

  def add_location_marker(map_data, %{location: {:ok, [%Geocode.Address{} | _]}} = assigns) do
    {:ok, [%{latitude: latitude, longitude: longitude, formatted: formatted} | _]} =
      assigns.location

    marker =
      Marker.new(
        latitude,
        longitude,
        id: "current-location",
        icon: "map-current-location",
        size: :mid,
        tooltip: formatted,
        z_index: 100
      )

    MapData.add_marker(map_data, marker)
  end

  def add_location_marker(map_data, _) do
    map_data
  end

  defp tooltip(%{stop: %{stop: %Stop{} = stop}, distance: distance, routes: routes}) do
    "_location_card.html"
    |> PartialView.render(%{
      stop: stop,
      distance: distance,
      routes: routes
    })
    |> HTML.safe_to_string()
  end

  defp tooltip(marker) do
    "_location_card.html"
    |> PartialView.render(marker)
    |> HTML.safe_to_string()
  end

  @spec flash_if_error(Conn.t()) :: Plug.Conn.t()
  def flash_if_error(%Conn{assigns: %{stops_json: [], location: {:ok, _}}} = conn) do
    put_flash(
      conn,
      :info,
      %FullscreenError{
        heading: "No MBTA service nearby",
        body:
          "There doesn't seem to be any stations found near the given address. Please try a different address to continue."
      }
    )
  end

  def flash_if_error(%Conn{assigns: %{location: {:error, :zero_results}}} = conn) do
    put_flash(
      conn,
      :info,
      %FullscreenError{heading: "We’re sorry", body: "We are unable to locate that address."}
    )
  end

  def flash_if_error(%Conn{assigns: %{location: {:error, _}}} = conn) do
    put_flash(
      conn,
      :info,
      %FullscreenError{
        heading: "We’re sorry",
        body: "There was an error locating that address. Please try again."
      }
    )
  end

  def flash_if_error(conn), do: conn
end
