defmodule Site.Mode.SubwayController do
  use Site.Mode.HubBehavior
  @subway_filters [[name: :subway, duration: :single_trip, reduced: nil],
                       [name: :subway, duration: :week, reduced: nil],
                       [name: :subway, duration: :month, reduced: nil]]

  def route_type, do: 1

  def routes do
    Routes.Repo.all
    |> Routes.Group.group
    |> Keyword.get(:subway)
  end

  def fares do
    @subway_filters |> Enum.flat_map(&Fares.Repo.all/1) |> Fares.Format.summarize(:bus_subway)
  end

  def mode_name, do: "Subway"

  def fare_description, do: "Travel anywhere on the Blue, Orange, Red, and Green lines for the same price."
end
