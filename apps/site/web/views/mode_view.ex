defmodule Site.ModeView do
  use Site.Web, :view

  def get_route_group(:commuter_rail = route_type, route_groups) do
    route_groups[route_type] |> Enum.sort_by(&(&1.name))
  end
  def get_route_group(:the_ride, _) do
    [{"MBTA Paratransit Program", redirect_path(Site.Endpoint, "riding_the_t/accessible_services/?id=7108")}]
  end
  def get_route_group(route_type, route_groups), do: route_groups[route_type]

  @spec fares_note(String) :: Phoenix.HTML.Safe.t | String.t
  @doc "Returns a note describing fares for the given mode"
  def fares_note("Commuter Rail") do
    content_tag :p do
      ["Fares for the Commuter Rail are separated into zones that depend on your origin and destination. Find your fare cost by entering your origin and destination
      or view ",
      link("table of fare zones.", to: fare_path(Site.Endpoint, :zone))]
    end
  end
  def fares_note(_mode) do
      ""
  end
end
