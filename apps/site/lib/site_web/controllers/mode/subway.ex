defmodule SiteWeb.Mode.SubwayController do
  use SiteWeb.Mode.HubBehavior

  def route_type, do: 1

  def routes do
    Routes.Repo.all
    |> Routes.Group.group
    |> Keyword.get(:subway, [])
  end

  def fares do
    SiteWeb.ViewHelpers.mode_summaries(:subway)
  end

  def mode_name, do: "Subway"

  def mode_icon, do: :subway

  def fare_description, do: "Travel anywhere on the Blue, Orange, Red, and Green lines for the same price."
end
