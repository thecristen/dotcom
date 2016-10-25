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
    [
      {"Inner Harbor Ferry", "$4.00"},
      {"Commuter Ferry", "$5.25"},
      {"Hingham or Hull to Logan Airport", "$18.50"},
      {"Zone 1A pass includes travel on Subway, Local Bus, Commuter Zone 1A, & Inner Harbor Ferry", "$84.50"},
      {"Commuter Ferry Pass includes travel on Commuter Zones 1-5, Subway, Local Bus, & Inner Harbor Ferry", "$308.00"}
    ]
  end
end
