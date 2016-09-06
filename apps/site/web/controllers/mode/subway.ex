defmodule Site.Mode.SubwayController do
  use Site.Mode.HubBehaviour

  def route_type, do: 1

  def routes do
    Routes.Repo.all
    |> Routes.Group.group
    |> Map.get(:subway)
  end

  def delays, do: mode_delays([0, 1])

  def mode_name, do: "Subway"

  def fare_description, do: "Travel anywhere on the Blue, Orange, Red, and Green lines for the same price."
end
