defmodule Site.Mode.FerryController do
  use Site.Mode.HubBehavior

  def route_type, do: 4

  def mode_name, do: "Ferry"

  def map_image_url, do: "/images/ferry-spider.jpg"

  def fare_description do
    "Fares differ between Commuter Ferries & Inner Harbor Ferries. Refer to the information below:"
  end

  def fares do
    Site.ViewHelpers.mode_summaries(:ferry)
  end
end
