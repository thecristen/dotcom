defmodule SiteWeb.TransitNearMeView do
  use SiteWeb, :view
  alias GoogleMaps.Geocode.Address
  alias Routes.Route
  alias SiteWeb.PartialView.SvgIconWithCircle
  alias Stops.Stop

  @spec render_routes(Route.gtfs_route_type() | Route.subway_lines_type(), [map]) ::
          Phoenix.HTML.Safe.t()
  def render_routes(:bus, routes) do
    content_tag(:span, [
      "Bus: ",
      route_links(routes)
    ])
  end

  def render_routes(:commuter_rail, routes) do
    [link("Commuter Rail", to: List.first(routes).href)]
  end

  def render_routes(_, routes) do
    route_links(routes)
  end

  @spec route_links([map]) :: [Phoenix.HTML.Safe.t()]
  defp route_links(routes) do
    routes
    |> Enum.map(&link(&1.name, to: &1.href))
    |> Enum.intersperse(content_tag(:span, ", "))
  end

  defp input_value({:ok, [%Address{formatted: address}]}) do
    address
  end

  defp input_value(_) do
    ""
  end

  def route_path(%Route{}, stop, :commuter_rail) do
    stop_v1_path(SiteWeb.Endpoint, :show, stop, tab: "schedule")
  end

  def route_path(%Route{} = route, stop, _route_group) do
    schedule_path(SiteWeb.Endpoint, :show, route, origin: stop.id)
  end

  def stop_path(%Stop{} = stop) do
    stop_v1_path(SiteWeb.Endpoint, :show, stop.id, tab: "schedule")
  end
end
