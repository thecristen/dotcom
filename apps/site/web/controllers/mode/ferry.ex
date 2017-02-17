defmodule Site.Mode.FerryController do
  use Site.Mode.HubBehavior

  def route_type, do: 4

  def mode_name, do: "Ferry"

  def map_image_url, do: "/images/ferry-spider.jpg"

  def map_pdf_url, do: "https://s3.amazonaws.com/mbta-dotcom/Water_Ferries_2016.pdf"

  def fare_description do
    "Fares differ between Commuter Ferries & Inner Harbor Ferries. Refer to the information below:"
  end

  def fares do
    Site.ViewHelpers.mode_summaries(:ferry)
  end
end
