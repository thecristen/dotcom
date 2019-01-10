defmodule SiteWeb.TransitNearMeController do
  use SiteWeb, :controller
  alias GoogleMaps.{Geocode, MapData, MapData.Layers, MapData.Marker}
  alias Phoenix.HTML
  alias SiteWeb.TransitNearMeView

  plug(SiteWeb.Plugs.TransitNearMe)

  def index(conn, _params) do
    if Laboratory.enabled?(conn, :transit_near_me_redesign) do
      conn
      |> assign_map_data()
      |> render("index.html", breadcrumbs: [Breadcrumb.build("Transit Near Me")])
    else
      render_404(conn)
    end
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

  def build_stop_marker(%{stop: %{station?: false}} = marker) do
    Marker.new(
      marker.stop.latitude,
      marker.stop.longitude,
      id: marker.stop.id,
      icon: "map-stop-marker",
      size: :large,
      tooltip: tooltip(marker)
    )
  end

  def build_stop_marker(marker) do
    Marker.new(
      marker.stop.latitude,
      marker.stop.longitude,
      id: marker.stop.id,
      icon: "map-station-marker",
      size: :large,
      tooltip: tooltip(marker)
    )
  end

  def add_location_marker(map_data, %{location: %Geocode.Address{}} = assigns) do
    %{latitude: latitude, longitude: longitude} = assigns.location

    marker =
      Marker.new(
        latitude,
        longitude,
        id: "current-location",
        icon: "map-current-location",
        size: :mid,
        tooltip: assigns.location.formatted,
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
end
