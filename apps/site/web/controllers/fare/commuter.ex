defmodule Site.FareController.Commuter do
  use Site.Fare.FareBehaviour

  def route_type, do: 2

  def mode_name, do: "Commuter Rail"

  def fares(conn) do
    if(conn.params["origin"] && conn.params["destination"]) do
      fare_name = Fares.calculate(Zones.Repo.get(conn.params["origin"]), Zones.Repo.get(conn.params["destination"]))

      fares = [name: fare_name]
      |> Fares.Repo.all()

      assign(conn, :fares, fares)
    end


  end

  def key_stops do
    Enum.map(["place-sstat", "place-north", "place-bbsta"], &Stations.Repo.get/1)
  end
end
