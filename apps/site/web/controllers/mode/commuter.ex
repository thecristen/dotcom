defmodule Site.Mode.CommuterRailController do
  use Site.Mode.HubBehavior
  import Phoenix.HTML.Link, only: [link: 2]

  def route_type, do: 2

  def mode_name, do: "Commuter Rail"

  def fare_description do
    [
      link_to_zone_fares(),
      " depend on the distance traveled (zones). Refer to the information below:"
    ]
  end

  def fares do
    Site.ViewHelpers.mode_summaries(:commuter_rail)
  end

  defp link_to_zone_fares do
    path = fare_path(Site.Endpoint, :show, "commuter_rail")
    link "Commuter Rail Fares", to: path
  end
end
