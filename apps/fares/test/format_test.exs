defmodule Fares.FormatTest do
  use ExUnit.Case, async: true
  alias Fares.Fare
  import Fares.Format

  test "fare price gets a string version of the price formatted nicely" do
    assert price(%Fare{cents: 925}) == "$9.25"
    assert price(%Fare{cents: 100}) == "$1.00"
  end

  describe "customers/1" do
    test "gets 'Student' when the fare applies to students" do
      assert customers(%Fare{reduced: :student}) == "Student"
    end

    test "gets 'Adult' when the fare does not have a reduced field" do
      assert customers(%Fare{}) == "Adult"
    end
  end

  describe "name/1" do
    test "uses the name of the CR zone" do
      assert name(%Fare{name: {:zone, "2"}}) == "Zone 2"
      assert name(%Fare{name: {:interzone, "3"}}) == "Interzone 3"
    end
  end

  test "duration/1" do
    assert duration(%Fare{duration: :single_trip}) == "One Way"
    assert duration(%Fare{duration: :round_trip}) == "Round Trip"
    assert duration(%Fare{duration: :month}) == "Monthly Pass"
    assert duration(%Fare{duration: :month, media: [:mticket]}) == "Monthly Pass on mTicket App"
    assert duration(%Fare{mode: :subway, duration: :single_trip}) == "Single Ride"
    assert duration(%Fare{mode: :bus, duration: :single_trip}) == "Single Ride"
  end
end
