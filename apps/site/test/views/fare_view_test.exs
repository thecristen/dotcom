defmodule Site.FareViewTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import Site.FareView
  alias Fares.Fare

  test "zone_name/1 gets the name of the fare zone" do
    assert zone_name({:zone, "2"}) == "Zone 2"
    assert zone_name({:interzone, "3"}) == "Interzone 3"
  end

  test "fare price gets a string version of the price formmated nicely" do
    assert fare_price(925) == "$9.25"
  end

  describe "fare_duration_summary/1" do
    test "fare duration is '1 Month' for a monthly fare" do
      assert fare_duration_summary(:month) == "1 Month"
    end

     test "fare duration is 'Round Trip' for a round-trip fare" do
       assert fare_duration_summary(:round_trip) == "Round Trip"
     end

     test "fare duration is 'One Way' for a one-way fare" do
       assert fare_duration_summary(:single_trip) == "One Way"
     end
  end

  test "fare_duration/1" do
    assert fare_duration(%Fare{duration: :single_trip}) == "One Way"
    assert fare_duration(%Fare{duration: :round_trip}) == "Round Trip"
    assert fare_duration(%Fare{duration: :month}) == "Monthly Pass"
    assert fare_duration(%Fare{duration: :month, pass_type: :mticket}) == "Monthly Pass on mTicket App"
    assert fare_duration(%Fare{mode: :subway, duration: :single_trip}) == "Single Ride"
    assert fare_duration(%Fare{mode: :bus, duration: :single_trip}) == "Single Ride"
  end

  describe "description/1" do
    test "fare description for one way CR is for commuter rail only" do
      fare = %Fare{duration: :single_trip, mode: :commuter}
      assert description(fare) == "Valid for Commuter Rail only."
    end

    test "fare description for CR round trip is for commuter rail only" do
      fare = %Fare{duration: :round_trip, mode: :commuter}
      assert description(fare) == "Valid for Commuter Rail only."
    end

    test "fare description for month is describes the modes it can be used on" do
      fare = %Fare{name: {:zone, "5"}, duration: :month, mode: :commuter}

      assert description(fare) ==
        "Valid for one calendar month of unlimited travel on Commuter Rail from " <>
        "Zones 1A-5 as well as Local Bus, Subway, Express Bus, and the Charlestown Ferry."
    end

    test "fare description for month mticket describes where it can be used" do
      fare = %Fare{name: {:zone, "5"}, duration: :month, pass_type: :mticket, mode: :commuter}

      assert description(fare) ==
        "Valid for one calendar month of travel on the commuter rail from zones 1A-5 only."
    end
  end

  describe "eligibility/1" do
    test "returns eligibility information for student fares" do
      assert eligibility(%Fare{mode: :commuter, reduced: :student}) =~
        "Middle and high school students are eligible"
    end

    test "returns eligibility information for senior fares" do
      assert eligibility(%Fare{mode: :commuter, reduced: :senior_disabled}) =~
        "Those who are 65 years of age or older"
    end

    test "returns eligibility information for adult fares" do
      assert eligibility(%Fare{mode: :commuter, reduced: nil}) =~
        "Those who are 12 years of age or older qualify for Adult fare pricing."
    end
  end

  describe "filter_reduced/2" do
    @fares [%Fare{name: {:zone, "6"}, reduced: nil}, %Fare{name: {:zone, "5"}, reduced: nil}, %Fare{name: {:zone, "6"}, reduced: :student}]

    test "filters out non-adult fares" do
      expected_fares = [%Fare{name: {:zone, "6"}, reduced: nil}, %Fare{name: {:zone, "5"}, reduced: nil}]
      assert filter_reduced(@fares, :adult) == expected_fares
    end

    test "filters out non-student fares" do
      expected_fares = [%Fare{name: {:zone, "6"}, reduced: :student}]
      assert filter_reduced(@fares, :student) == expected_fares
    end
  end

  describe "fare_customers/1" do
    test "gets 'Student' when the fare applies to students" do
      assert fare_customers(:student) == "Student"
    end

    test "gets 'Adult' when the fare does not have a reduced field" do
      assert fare_customers(nil) == "Adult"
    end
  end

  describe "vending_machine_stations/0" do
    test "generates a list of links to stations with fare vending machines" do
      assert vending_machine_stations =~ "place-north"
      assert vending_machine_stations =~ "place-sstat"
      assert vending_machine_stations =~ "place-bbsta"
      assert vending_machine_stations =~ "place-brntn"
      assert vending_machine_stations =~ "place-forhl"
      assert vending_machine_stations =~ "place-jfk"
      assert vending_machine_stations =~ "Lynn"
      assert vending_machine_stations =~ "place-mlmnl"
      assert vending_machine_stations =~ "place-portr"
      assert vending_machine_stations =~ "place-qnctr"
      assert vending_machine_stations =~ "place-rugg"
      assert vending_machine_stations =~ "Worcester"
    end
  end
end
