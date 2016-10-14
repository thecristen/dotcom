defmodule Site.FareView do
  use Site.Web, :view

  def zone_name({zone, number}) do
    "#{String.capitalize(Atom.to_string(zone))} #{number}"
  end

  def fare_price(fare_in_cents) do
    "$#{Float.to_string(fare_in_cents / 100, decimals: 2)}"
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
  def description(%Fare{duration: :month, pass_type: :mticket, name: {_, "1A"}}) do
    "Valid for one calendar month of travel on the commuter rail in zone 1A only."
  end
  def description(%Fare{duration: :month, pass_type: :mticket, name: {_zone, number}}) do
    "Valid for one calendar month of travel on the commuter rail from zones 1A-#{number} only."
  end
  def description(%Fare{duration: :month, name: {_, "1A"}}) do
    "Valid for one calendar month of unlimited travel on Commuter Rail in zone 1A as well as Local Bus, Subway, " <>
    "Express Bus, and the Charlestown Ferry."
  end
  def description(%Fare{duration: :month, name: {_zone, number}}) do
    "Valid for one calendar month of unlimited travel on Commuter Rail from Zones 1A-#{number} as well as Local " <>
    "Bus, Subway, Express Bus, and the Charlestown Ferry."
  end
end
