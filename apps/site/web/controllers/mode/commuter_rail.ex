defmodule Site.Mode.CommuterRailController do
  use Site.Mode.HubBehaviour
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import Phoenix.HTML, only: [safe_to_string: 1]
  import Site.ViewHelpers, only: [redirect_path: 2]

  def route_type, do: 2

  def mode_name, do: "Commuter Rail"

  def map_image_url, do: "/images/commuter-rail-spider.jpg"

  def map_pdf_url do
    "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Commuter%20Rail%20Map.pdf"
  end

  def fare_description do
    "#{link_to_zone_fares} depend on the distance traveled (zones). Read the information below:"
  end

  defp link_to_zone_fares do
    path = redirect_path(Site.Endpoint, "fares_and_passes/rail/")
    tag = content_tag :a, "Commuter Rail Fares", href: path

    safe_to_string(tag)
  end

  def fares do
    [
      {"Zones 1A-10", "$2.10 - $11.50"},
      {"Monthly Pass, unlimited travel to and from your zone plus travel on" <>
        " all buses, subway, and Inner Harbor Ferry",
       "$75 - $362"},
      {"Seniors and Persons with Disabilities", "50% discount"}
    ]
  end
end
