defmodule Site.Mode.BoatController do
  use Site.Mode.HubBehaviour

  def route_type, do: 4

  def mode_name, do: "Boat"

  def map_image_url, do: "/images/boat-spider.jpg"

  def map_pdf_url, do: nil

  def fare_description do
    "Fares differ between Commuter Boats & Inner Harbor Ferries."
  end

  def fares do
    [
      {"Inner Harbor Ferry", "$4.00"},
      {"Commuter Boat", "$5.25"},
      {"Hingham or Hull to Logan Airport", "$18.50"},
      {"Zone 1A pass includes travel on Subway, Local Bus, Commuter Zone 1A, & Inner Harbor Ferry", "$84.50"},
      {"Commuter Boat Pass includes travel on Commuter Zones 1-5, Subway, Local Bus, & Inner Harbor Ferry", "$308.00"}
    ]
  end
end
