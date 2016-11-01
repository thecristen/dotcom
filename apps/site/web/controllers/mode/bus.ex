defmodule Site.Mode.BusController do
  use Site.Mode.HubBehavior
  require Logger
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import Phoenix.HTML, only: [safe_to_string: 1]
  import Site.ViewHelpers, only: [redirect_path: 2]

  # @bus_filters [[name: :local_bus, duration: :single_trip, reduced: nil, ],
  # [name: :subway, duration: :month, reduced: nil]]

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

  def display, do: @bus_filters

  defp link_to_bus_fares do
    path = redirect_path(Site.Endpoint, "fares_and_passes/bus/")
    tag = content_tag :a, "Bus Fares", href: path

    safe_to_string(tag)
  end
end
