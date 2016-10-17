defmodule Site.FareViewTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Site.FareView
  alias Fares.Fare

  test "zone_name gets the name of the zone for the fare given two stops" do
    assert FareView.zone_name({:zone, "2"}) == "Zone 2"
  end

  test "fare price gets a string version of the price formmated nicely" do
    assert FareView.fare_price(925) == "$9.25"
  end

  describe "fare_duration/1" do
    test "fare duration is '1 Month' for a monthly fare" do
      assert FareView.fare_duration(:month) == "1 Month"
    end

     test "fare duration is 'Round Trip' for a round-trip fare" do
       assert FareView.fare_duration(:round_trip) == "Round Trip"
     end

     test "fare duration is 'One Way' for a one-way fare" do
       assert FareView.fare_duration(:single_trip) == "One Way"
     end
  end

  describe "description/1" do
    test "fare description for one way is for commuter rail only" do
      fare = %Fare{duration: :single_trip}
      assert FareView.description(fare) == "Valid for Commuter Rail only."
    end

    test "fare description for round trip is for commuter rail only" do
      fare = %Fare{duration: :round_trip}
      assert FareView.description(fare) == "Valid for Commuter Rail only."
    end

    test "fare description for month is describes the modes it can be used on" do
      fare = %Fare{name: {:zone, "5"}, duration: :month}

      assert FareView.description(fare) ==
        "Valid for one calendar month of unlimited travel on Commuter Rail from " <>
        "Zones 1A-5 as well as Local Bus, Subway, Express Bus, and the Charlestown Ferry."
    end

    test "fare description for month mticket describes where it can be used" do
      fare = %Fare{name: {:zone, "5"}, duration: :month, pass_type: :mticket}

      assert FareView.description(fare) ==
        "Valid for one calendar month of travel on the commuter rail from zones 1A-5 only."
    end
  end

  describe "eligibility/1" do
    test "FareView.eligibility returns eligibility information for a mode" do
      assert FareView.eligibility(%Fare{mode: :commuter, reduced: :student}) =~ "Middle and high school students are eligible"
    end

    test "FareView.eligibility returns eligibility information for adult" do
      assert FareView.eligibility(%Fare{mode: :commuter, reduced: nil}) =~ "Those who are 12 years of age or older qualify for Adult fare pricing."
    end
  end

  describe "filter_fares/2" do
    test "filters out non-adult fares" do
      fares = Fares.Repo.all(name: :zone_6)
      expected_fares = Fares.Repo.all(name: :zone_6, reduced: nil)
      assert FareView.filter_fares(fares, "adult") == expected_fares
    end

    test "filters out non-student fares" do
      fares = Fares.Repo.all(name: :zone_6)
      expected_fares = Fares.Repo.all(name: :zone_6, reduced: :student)
      assert FareView.filter_fares(fares, "student") == expected_fares
    end
  end
end

