defmodule Site.Mode.SubwayController do
  use Site.Mode.HubBehavior

  def route_type, do: 1

  def routes do
    Routes.Repo.all
    |> Routes.Group.group
    |> Keyword.get(:subway)
  end

  def fares do
    Site.ViewHelpers.mode_summaries(:subway)
  end

  def mode_name, do: "Subway"

  def fare_description, do: "Travel anywhere on the Blue, Orange, Red, and Green lines for the same price."
end
