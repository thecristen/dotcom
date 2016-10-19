defmodule Site.FareController.Commuter do
  use Site.Fare.FareBehaviour

  def route_type, do: 2

  def mode_name, do: "Commuter Rail"

  def fares(origin, destination) when not is_nil(origin) and not is_nil(destination) do
    fare_name = Fares.calculate(Zones.Repo.get(origin.id), Zones.Repo.get(destination.id))

    [name: fare_name]
    |> Fares.Repo.all()
  end
  def fares(_origin, _destination) do
    []
  end

  def key_stops do
    Enum.map(["place-sstat", "place-north", "place-bbsta"], &Stations.Repo.get/1)
  end
end
