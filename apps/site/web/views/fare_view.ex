defmodule Site.FareView do
  use Site.Web, :view

  def zone_name(origin, destination) do
    origin_zone = Zones.Repo.get(origin)
    destination_zone = Zones.Repo.get(destination)

    zone_atom = Fares.calculate(origin_zone, destination_zone)

    zone_atom
    |> Atom.to_string
    |> String.capitalize
    |> String.replace("_", " ")
  end

  def fare_price(fare) do
    "$#{Float.to_string(fare.cents / 100, decimals: 2)}"
  end

  def fare_duration(:month) do
    "1 Month"
  end
  def fare_duration(:round_trip) do
    "Round Trip"
  end
  def fare_duration(:single_trip) do
    "One Way"
  end

  def description(%Fare{duration: :single_trip}) do
    "Valid for Commuter Rail only."
  end
  def description(%Fare{duration: :round_trip}) do
    "Valid for Commuter Rail only."
  end
  def description(%Fare{duration: :month, pass_type: :mticket, number: "1A"}) do
    "Valid for one calendar month of travel on the commuter rail in zone 1A only."
  end
  def description(%Fare{duration: :month, pass_type: :mticket, number: number}) do
    "Valid for one calendar month of travel on the commuter rail from zones 1A-#{number} only."
  end
  def description(%Fare{duration: :month, number: "1A"}) do
    "Valid for one calendar month of unlimited travel on Commuter Rail in zone 1A as well as Local Bus, Subway, Express Bus, and the Charlestown Ferry."
  end
  def description(%Fare{duration: :month, number: number}) do
    "Valid for one calendar month of unlimited travel on Commuter Rail from Zones 1A-#{number} as well as Local Bus, Subway, Express Bus, and the Charlestown Ferry."
  end
end
