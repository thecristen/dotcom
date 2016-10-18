defmodule Site.FareController.Commuter do
  use Site.Fare.FareBehaviour

  def route_type, do: 2

  def mode_name, do: "Commuter Rail"

  def fares(origin, destination) do
    if(origin && destination) do
      fare_name = Fares.calculate(Zones.Repo.get(origin), Zones.Repo.get(destination))

      fares = [name: fare_name]
      |> Fares.Repo.all()
    else
      []
    end
  end

  def key_stops do
    Enum.map(["place-sstat", "place-north", "place-bbsta"], &Stations.Repo.get/1)
  end
end
