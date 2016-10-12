defmodule Site.FareViewTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Site.FareView

  @fares Fares.Repo.all

  test "zone_name gets the name of the zone for the fare given two stops" do
    assert FareView.zone_name("place-sstat", "Anderson/ Woburn") == "Zone 2"
  end

  test "fare price gets a string version of the price formmated nicely" do
    fare = @fares
    |> Fares.Repo.filter(%{duration: :single_trip, name: :zone_5})
    |> List.first

    assert FareView.fare_price(fare) == "$9.25"
  end

  test "fare duration is '1 Month' for a monthly fare" do
    fare = @fares
    |> Fares.Repo.filter(%{duration: :month})
    |> List.first
    assert FareView.fare_duration(fare.duration) == "1 Month"
  end

   test "fare duration is 'Round Trip' for a round-trip fare" do
     fare = @fares
     |> Fares.Repo.filter(%{duration: :round_trip})
     |> List.first
     assert FareView.fare_duration(fare.duration) == "Round Trip"
   end

   test "fare duration is 'One Way' for a one-way fare" do
     fare = @fares
     |> Fares.Repo.filter(%{duration: :single_trip})
     |> List.first
     assert FareView.fare_duration(fare.duration) == "One Way"
   end

   test "fare description for one way is for commuter rail only" do
     fare = @fares
     |> Fares.Repo.filter(%{duration: :single_trip})
     |> List.first
     assert FareView.description(fare) == "Valid for Commuter Rail only."
   end

   test "fare description for round trip is for commuter rail only" do
     fare = @fares
     |> Fares.Repo.filter(%{duration: :round_trip})
     |> List.first
     assert FareView.description(fare) == "Valid for Commuter Rail only."
   end

   test "fare description for month is describes the modes it can be used on" do
     fare = @fares
     |> Fares.Repo.filter(%{name: :zone_5, duration: :month})
     |> List.first
     assert FareView.description(fare) == "Valid for one calendar month of unlimited travel on Commuter Rail from Zones 1A-5 as well as Local Bus, Subway, Express Bus, and the Charlestown Ferry."
   end

   test "fare description for month mticket describes where it can be used" do
     fare = @fares
     |> Fares.Repo.filter(%{number: "5", duration: :month, pass_type: :mticket})
     |> List.first
     assert FareView.description(fare) == "Valid for one calendar month of travel on the commuter rail from zones 1A-5 only."
   end
end#
