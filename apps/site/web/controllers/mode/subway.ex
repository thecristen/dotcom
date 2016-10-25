defmodule Site.Mode.SubwayController do
  use Site.Mode.HubBehavior

  def route_type, do: 1

  def routes do
    Routes.Repo.all
    |> Routes.Group.group
    |> Dict.get(:subway)
  end

  def delays, do: Site.Mode.HubBehavior.mode_delays([0, 1])

  def mode_name, do: "Subway"

  def fare_description, do: "Travel anywhere on the Blue, Orange, Red, and Green lines for the same price."
end
