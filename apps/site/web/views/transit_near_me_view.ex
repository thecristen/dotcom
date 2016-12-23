defmodule Site.TransitNearMeView do
  use Site.Web, :view
  alias Routes.Route

  @spec get_type_list(Route.gtfs_route_type | Route.subway_lines_type, [Route.t]) :: String.t
  def get_type_list(:bus, routes) do
    "Bus: #{route_name_list(routes)}" |> Phoenix.HTML.raw
  end
  def get_type_list(type, _) do
    "#{mode_name(type)}"
  end

  @spec route_name_list([Route.t]) :: String.t
  def route_name_list(routes) do
    routes
    |> Enum.map(&(&1.name))
    |> Enum.join(", ")
  end

  @doc """
  assigns a class based on the size of the result set:
  - 7 results or less: "small-set"
  - 8 results or more: "large-set"
  """
  @spec result_container_classes(String.t, [{Routes.Route.gtfs_route_type | Route.subway_lines_type, [Route.t]}]) :: String.t
  def result_container_classes(class, []), do: class <> " empty"
  def result_container_classes(class, routes) when length(routes) >= 8, do: class <> " large-set"
  def result_container_classes(class, _), do: class <> " small-set"
end
