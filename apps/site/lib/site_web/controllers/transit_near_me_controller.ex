defmodule SiteWeb.TransitNearMeController do
  use SiteWeb, :controller
  alias GoogleMaps.{Geocode, MapData, MapData.Layers, MapData.Marker}
  alias Phoenix.HTML
  alias Plug.Conn
  alias SiteWeb.TransitNearMeController.{Location, StopsWithRoutes}
  alias SiteWeb.TransitNearMeView

  def index(conn, _params) do
    if Laboratory.enabled?(conn, :transit_near_me_redesign) do
      conn
      |> assign(:requires_google_maps?, true)
      |> assign_location()
      |> assign_stops()
      |> assign_map_data()
      |> flash_if_error()
      |> render("index.html", breadcrumbs: [Breadcrumb.build("Transit Near Me")])
    else
      render_404(conn)
    end
  end

  defp assign_location(conn) do
    location_fn = Map.get(conn.assigns, :location_fn, &Location.get/2)

    location = location_fn.(conn.params, [])

    assign(conn, :location, location)
  end

  defp assign_stops(%{assigns: %{location: {:ok, [location | _]}}} = conn) do
    stops_with_routes_fn = Map.get(conn.assigns, :stops_with_routes_fn, &StopsWithRoutes.get/2)

    stops_with_routes = stops_with_routes_fn.(location, [])

    assign(conn, :stops_with_routes, stops_with_routes)
  end

  defp assign_stops(conn) do
    assign(conn, :stops_with_routes, [])
  end

  def assign_map_data(conn) do
    markers =
      conn.assigns.stops_with_routes
      |> Enum.map(&build_stop_marker(&1))

    map_data =
      {630, 400}
      |> MapData.new(14)
      |> MapData.add_layers(%Layers{transit: true})
      |> MapData.add_markers(markers)
      |> add_location_marker(conn.assigns)

    assign(conn, :map_data, map_data)
  end

  def build_stop_marker(marker) do
    Marker.new(
      marker.stop.latitude,
      marker.stop.longitude,
      id: marker.stop.id,
      icon: marker_for_stop_type(marker.stop),
      size: :large,
      tooltip: tooltip(marker)
    )
  end

  def marker_for_stop_type(%{station?: false}) do
    "map-stop-marker"
  end

  def marker_for_stop_type(_) do
    "map-station-marker"
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

  defp tooltip(marker) do
    "_location_card.html"
    |> TransitNearMeView.render(marker)
    |> HTML.safe_to_string()
  end

  @spec flash_if_error(Conn.t()) :: Plug.Conn.t()
  def flash_if_error(%Conn{assigns: %{stops_with_routes: [], location: {:ok, _}}} = conn) do
    put_flash(
      conn,
      :info,
      "There doesn't seem to be any stations found near the given address. Please try a different address to continue."
    )
  end

  def flash_if_error(%Conn{assigns: %{location: {:error, :zero_results}}} = conn) do
    put_flash(
      conn,
      :info,
      "We are unable to locate that address."
    )
  end

  def flash_if_error(%Conn{assigns: %{location: {:error, _}}} = conn) do
    put_flash(
      conn,
      :info,
      "There was an error locating that address. Please try again."
    )
  end

  def flash_if_error(conn), do: conn
end
