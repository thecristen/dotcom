defmodule Site.Mode.FerryController do
  use Site.Mode.HubBehavior

  @ferry_filters [[mode: :ferry, duration: :single_trip, reduced: nil],
                  [mode: :ferry, duration: :month, reduced: nil]]

  def route_type, do: 4

  def mode_name, do: "Ferry"

  def map_image_url, do: "/images/ferry-spider.jpg"

  def map_pdf_url, do: "https://s3.amazonaws.com/mbta-dotcom/Water_Ferries_2016.pdf"

  def fare_description do
    "Fares differ between Commuter Ferries & Inner Harbor Ferries. Refer to the information below:"
  end

  def fares do
    @ferry_filters |> Enum.flat_map(&Fares.Repo.all/1) |> Fares.Format.summarize(:ferry)
  end
end
