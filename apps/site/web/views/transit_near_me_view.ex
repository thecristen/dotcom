defmodule Site.TransitNearMeView do
  use Site.Web, :view
  alias Routes.Route

  @spec get_type_list(Route.gtfs_route_type | Route.subway_lines_type, [Route.t]) :: String.t
  defp get_type_list(type, routes) when type in [:commuter, :bus, :ferry] do
    "<strong>#{mode_name(type)}</strong>: #{route_name_list(routes)}" |> Phoenix.HTML.raw
  end
  defp get_type_list(type, _) do
    "#{mode_name(type)}"
  end

  @spec route_name_list([Route.t]) :: String.t
  def route_name_list(routes) do
    routes
    |> Enum.map(&(&1.name))
    |> Enum.join(", ")
  end
end
