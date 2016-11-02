defmodule Site.Mode.CommuterRailController do
  use Site.Mode.HubBehavior
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import Phoenix.HTML, only: [safe_to_string: 1]

  @commuter_filters [[mode: :commuter, duration: :single_trip, reduced: nil],
                     [mode: :commuter, duration: :month, reduced: nil]]

  def route_type, do: 2

  def mode_name, do: "Commuter Rail"

  def map_image_url, do: "/images/commuter-rail-spider.jpg"

  def map_pdf_url do
    "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Commuter%20Rail%20Map.pdf"
  end

  def fare_description do
    "#{link_to_zone_fares} depend on the distance traveled (zones). Refer to the information below:"
  end

  def fares do
    @commuter_filters |> Enum.flat_map(&Fares.Repo.all/1) |> Fares.Format.summarize(:commuter)
  end

  defp link_to_zone_fares do
    path = fare_path(Site.Endpoint, :show, "commuter")
    tag = content_tag :a, "Commuter Rail Fares", href: path

    safe_to_string(tag)
  end
end
