defmodule Site.ModeView do
  use Site.Web, :view

  def get_route_group(:bus = route_type, route_groups, true) do
    route_groups[route_type] |> Enum.filter(&Routes.Route.key_route?/1)
  end

  def get_route_group(:subway = route_type, route_groups, true) do
    route_groups[route_type] |> Enum.filter(&Routes.Route.key_route?/1)
  end

  def get_route_group(:commuter_rail = route_type, route_groups, _) do
    route_groups[route_type] |> Enum.sort_by(&(&1.name))
  end

  def get_route_group(route_type, route_groups, _), do: route_groups[route_type]

end
