defmodule Site.Mode.BusController do
  use Site.Mode.HubBehavior
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import Phoenix.HTML, only: [safe_to_string: 1]

  def route_type, do: 3

  def mode_name, do: "Bus"

  def fare_description do
    "For Inner and Outer Express Bus fares, read the complete #{link_to_bus_fares()} page."
  end

  def fares do
    Site.ViewHelpers.mode_summaries(:bus)
  end

  defp link_to_bus_fares do
    path = fare_path(Site.Endpoint, :show,  "bus_subway")
    tag = content_tag :a, "Bus Fares", href: path

    safe_to_string(tag)
  end
end
