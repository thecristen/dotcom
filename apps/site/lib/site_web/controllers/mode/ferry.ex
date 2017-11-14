defmodule SiteWeb.Mode.FerryController do
  use SiteWeb.Mode.HubBehavior

  def route_type, do: 4

  def mode_name, do: "Ferry"

  def fare_description do
    "Fares differ between Commuter Ferries & Inner Harbor Ferries. Refer to the information below:"
  end

  def fares do
    SiteWeb.ViewHelpers.mode_summaries(:ferry)
  end
end
