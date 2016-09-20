defmodule Site.ModeView do
  use Site.Web, :view

  def get_route_group(:bus = route_type, route_groups, true) do
    route_groups[route_type] |> Enum.filter(&(&1.key_route?))
  end

  def get_route_group(route_type, route_groups, _), do: route_groups[route_type]

end
