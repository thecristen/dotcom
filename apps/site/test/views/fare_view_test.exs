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
    test "fare duration is 'Monthly Pass' for a monthly fare" do
      assert FareView.fare_duration(%Fare{duration: :month}) == "Monthly Pass"
    end

    test "fare duration is 'Monthly Pass on mTicket app' for a monthly mTicket fare" do
      assert FareView.fare_duration(%Fare{duration: :month, pass_type: :mticket}) ==
        "Monthly Pass on mTicket app"
    end

     test "fare duration is 'Round Trip' for a round-trip fare" do
       assert FareView.fare_duration(%Fare{duration: :round_trip}) == "Round Trip"
     end

     test "fare duration is 'One Way' for a one-way fare" do
       assert FareView.fare_duration(%Fare{duration: :single_trip}) == "One Way"
     end
  end

  describe "description/1" do
    test "fare description for one way CR is for commuter rail only" do
      fare = %Fare{duration: :single_trip, mode: :commuter}

      assert FareView.description(fare) == "Valid for Commuter Rail only."
    end

    test "fare description for CR round trip is for commuter rail only" do
      fare = %Fare{duration: :round_trip, mode: :commuter}

      assert FareView.description(fare) == "Valid for Commuter Rail only."
    end

    test "fare description for month is describes the modes it can be used on" do
      fare = %Fare{name: {:zone, "5"}, duration: :month, mode: :commuter}

      assert FareView.description(fare) ==
        "Valid for one calendar month of unlimited travel on Commuter Rail from " <>
        "Zones 1A-5 as well as Local Bus, Subway, Express Bus, and the Charlestown Ferry."
    end

    test "fare description for month mticket describes where it can be used" do
      fare = %Fare{name: {:zone, "5"}, duration: :month, pass_type: :mticket, mode: :commuter}

      assert FareView.description(fare) ==
        "Valid for one calendar month of travel on the commuter rail from zones 1A-5 only."
    end
  end

  describe "eligibility/1" do
    test "returns eligibility information for student fares" do
      assert FareView.eligibility(%Fare{mode: :commuter, reduced: :student}) =~
        "Middle and high school students are eligible"
    end

    test "returns eligibility information for senior fares" do
      assert FareView.eligibility(%Fare{mode: :commuter, reduced: :senior_disabled}) =~
        "Those who are 65 years of age or older"
    end

    test "returns eligibility information for adult fares" do
      assert FareView.eligibility(%Fare{mode: :commuter, reduced: nil}) =~
        "Those who are 12 years of age or older qualify for Adult fare pricing."
    end
  end

  describe "filter_fares/2" do
    @fares [%Fare{name: {:zone, "6"}, reduced: nil}, %Fare{name: {:zone, "5"}, reduced: nil}, %Fare{name: {:zone, "6"}, reduced: :student}]

    test "filters out non-adult fares" do
      expected_fares = [%Fare{name: {:zone, "6"}, reduced: nil}, %Fare{name: {:zone, "5"}, reduced: nil}]
      assert FareView.filter_fares(@fares, "adult") == expected_fares
    end

    test "filters out non-student fares" do
      expected_fares = [%Fare{name: {:zone, "6"}, reduced: :student}]
      assert FareView.filter_fares(@fares, "student") == expected_fares
    end
  end

  describe "fare_customers/1" do
    test "gets 'Student' when the fare applies to students" do
      assert FareView.fare_customers(:student) == "Student"
    end

    test "gets 'Adult' when the fare does not have a reduced field" do
      assert FareView.fare_customers(nil) == "Adult"
    end
  end

  describe "applicable_fares/2" do
    test "returns fare filters for adult fares on the commuter rail" do
      assert FareView.applicable_fares(nil, 2) == [
        %{reduced: nil, duration: :single_trip},
        %{reduced: nil, duration: :round_trip},
        %{reduced: nil, duration: :month},
        %{duration: :month, pass_type: :mticket, reduced: nil}
      ]
    end

    test "returns fare filters for student fares on ferries" do
      assert FareView.applicable_fares(:student, 4) == [
        %{reduced: :student, duration: :single_trip},
        %{reduced: :student, duration: :round_trip}
      ]
    end
  end
end

