defmodule SiteWeb.TransitNearMeView do
  use SiteWeb, :view
  alias Routes.Route
  alias Stops.Stop
  alias SiteWeb.PartialView.SvgIconWithCircle

  @spec render_routes(Route.gtfs_route_type | Route.subway_lines_type, [Route.t], Stop.t) :: Phoenix.HTML.Safe.t
  def render_routes(:bus, routes, stop) do
    content_tag(:span, [
      "Bus: ",
      route_links(routes, stop)
    ])
  end
  def render_routes(:commuter_rail, _, stop) do
    link("Commuter Rail", to: stop_path(SiteWeb.Endpoint, :show, stop, tab: "schedule"))
  end
  def render_routes(_, [%Route{} = route], stop) do
    route_link(route, stop)
  end

  @spec route_links([Route.t], Stop.t) :: [Phoenix.HTML.Safe.t]
  defp route_links(routes, stop) do
    routes
    |> Enum.map(&route_link(&1, stop))
    |> Enum.intersperse(content_tag(:span, ", "))
  end

  defp route_link(%Route{} = route, %Stop{id: stop_id}) do
    path = schedule_path(SiteWeb.Endpoint, :show, route, origin: stop_id)
    link(route.name, to: path)
  end

  @doc """
  assigns a class based on the size of the result set:
  - 7 results or less: "small-set"
  - 8 results or more: "large-set"
  """
  @spec result_container_classes(String.t, [{Routes.Route.gtfs_route_type | Route.subway_lines_type, [Route.t]}])
  :: String.t
  def result_container_classes(class, []), do: class <> " empty"
  def result_container_classes(class, routes) when length(routes) >= 8, do: class <> " large-set"
  def result_container_classes(class, _), do: class <> " small-set"
end
