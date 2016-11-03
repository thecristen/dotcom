defmodule Site.Mode.BusController do
  use Site.Mode.HubBehavior
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import Phoenix.HTML, only: [safe_to_string: 1]

  @bus_filters [[name: :local_bus, duration: :single_trip, reduced: nil],
                       [name: :subway, duration: :week, reduced: nil],
                       [name: :subway, duration: :month, reduced: nil]]

  def route_type, do: 3

  def mode_name, do: "Bus"

  def fare_description do
    "For Inner and Outer Express Bus fares, read the complete #{link_to_bus_fares} page."
  end

  def fares do
    @bus_filters |> Enum.flat_map(&Fares.Repo.all/1) |> Fares.Format.summarize(:bus_subway)
  end

  defp link_to_bus_fares do
    path = fare_path(Site.Endpoint, :show,  "bus_subway")
    tag = content_tag :a, "Bus Fares", href: path

    safe_to_string(tag)
  end
end
