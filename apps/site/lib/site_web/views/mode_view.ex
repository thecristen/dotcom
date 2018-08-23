defmodule SiteWeb.ModeView do
  use SiteWeb, :view
  alias SiteWeb.PartialView.SvgIconWithCircle

  def get_route_group(:commuter_rail = route_type, route_groups) do
    # Note that we do not sort the commuter rail routes by name as we
    # want to preserve the order supplied by the API, keeping Foxboro
    # last.
    route_groups[route_type]
  end
  def get_route_group(:the_ride, _) do
    [{"MBTA Paratransit Program", cms_static_page_path(SiteWeb.Endpoint, "/accessibility/the-ride")}]
  end
  def get_route_group(route_type, route_groups), do: route_groups[route_type]

  @spec fares_note(String) :: Phoenix.HTML.safe | String.t
  @doc "Returns a note describing fares for the given mode"
  def fares_note("Commuter Rail") do
    content_tag :p do
      ["Fares for the Commuter Rail are separated into zones that depend on your origin and destination. Find your fare cost by entering your origin and destination
      or view ",
      link("table of fare zones.", to: cms_static_page_path(SiteWeb.Endpoint, "/fares/commuter-rail-fares/zones"))]
    end
  end
  def fares_note(_mode) do
      ""
  end
end
