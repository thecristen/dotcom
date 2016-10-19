defmodule Site.FareController.BusSubway do
  use Site.Fare.FareBehaviour

  def mode_name(), do: "Bus/Subway"

  def template(), do: "bus_subway.html"

  def fares(_conn) do
    [:subway, :local_bus, :inner_express_bus, :outer_express_bus]
    |> Enum.flat_map(&Fares.Repo.all(mode: &1))
  end
end
