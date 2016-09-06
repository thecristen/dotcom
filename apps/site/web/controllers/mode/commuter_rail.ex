defmodule Site.Mode.CommuterRailController do
  use Site.Mode.HubBehaviour

  def route_type, do: 2

  def mode_name, do: "Commuter Rail"

  def map_image_url, do: "/images/commuter-rail-spider.jpg"

  def map_pdf_url do
    "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Commuter%20Rail%20Map.pdf"
  end

  def fare_description do
    "Commuter Rail fares depend on the distance traveled (zones). Read the information below:"
  end

  def fares do
    [
      {"Zones 1A-10", "$2.10-11.50"},
      {"Monthly Pass, unlimited travel to and from your zone plus travel on" <>
        " all buses, subway, and Inner Harbor Ferry",
       "$75-362"},
      {"Seniors and Persons with Disabilities", "50%"}
    ]
  end
end
