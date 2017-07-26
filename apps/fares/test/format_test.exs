defmodule Fares.FormatTest do
  use ExUnit.Case, async: true
  alias Fares.{Fare, Summary}
  import Fares.Format

  test "fare price gets a string version of the price formatted nicely" do
    assert price(%Fare{cents: 925}) == "$9.25"
    assert price(%Fare{cents: 100}) == "$1.00"
  end

  test "fare price returns empty string when fare is nil" do
    assert price(nil) == ""
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

    test "gives a printable name when given the name of a fare" do
      assert name({:zone, "6"}) == "Zone 6"
      assert name({:interzone, "4"}) == "Interzone 4"
    end

    test "gives a descriptive name for bus fares" do
      assert name(%Fare{name: :local_bus}) == "Local Bus"
      assert name(%Fare{name: :inner_express_bus}) == "Inner Express Bus"
      assert name(%Fare{name: :outer_express_bus}) == "Outer Express Bus"
    end

    test "gives a descriptive name for ferry fares" do
      assert name(%Fare{name: :ferry_inner_harbor}) == "Inner Harbor Ferry"
      assert name(%Fare{name: :ferry_cross_harbor}) == "Cross Harbor Ferry"
      assert name(%Fare{name: :commuter_ferry}) == "Commuter Ferry"
    end
  end

  test "duration/1" do
    assert duration(%Fare{duration: :single_trip}) == "One Way"
    assert duration(%Fare{duration: :round_trip}) == "Round Trip"
    assert duration(%Fare{duration: :month}) == "Monthly Pass"
    assert duration(%Fare{duration: :month, media: [:mticket]}) == "Monthly Pass on mTicket App"
    assert duration(%Fare{mode: :subway, duration: :single_trip}) == "One Way"
    assert duration(%Fare{mode: :bus, duration: :single_trip}) == "One Way"
    assert duration(%Fare{name: :ferry_inner_harbor, duration: :day}) == "One-Day Pass"
  end

  describe "summarize/2" do
    test "bus subway groups them by name/duration/modes" do
      base = %Fare{name: :subway, mode: :subway}
      single_trip_cash = %{base | duration: :single_trip, media: [:cash], cents: 100}
      single_trip_charlie_card = %{base | duration: :single_trip, media: [:charlie_card], cents: 200}
      week_pass = %{base | duration: :week, media: [:charlie_card], cents: 300, additional_valid_modes: [:bus]}
      month_pass = %{base | duration: :month, media: [:charlie_card, :charlie_ticket], cents: 400}

      actual = summarize([single_trip_cash, single_trip_charlie_card, week_pass, month_pass], :bus_subway)
      expected = [
        %Summary{
          name: ["Subway", " ", "One Way"],
          duration: :single_trip,
          fares: [{"Cash", "$1.00"}, {"CharlieCard", "$2.00"}],
          modes: [:subway]
        },
        %Summary{
          name: "7-Day Pass",
          duration: :week,
          fares: [{"CharlieCard", "$3.00"}],
          modes: [:subway, :bus]
        },
        %Summary{
          name: "Monthly LinkPass",
          duration: :month,
          fares: [{"CharlieCard or CharlieTicket", "$4.00"}],
          modes: [:subway]
        }
      ]
      assert actual == expected
    end

    test "commuter rail groups them by single/multiple trip and groups prices" do
      base = %Fare{name: :commuter_rail, mode: :commuter_rail, duration: :single_trip}
      cheap = %{base | name: {:zone, "1"}, cents: 100}
      expensive = %{base | name: {:zone, "10"}, cents: 200}

      actual = summarize([cheap, expensive], :commuter_rail)
      expected = [
        %Summary{
          name: "One Way",
          duration: :single_trip,
          fares: [{"Zones 1A-10", ["$1.00", " - ", "$2.00"]}],
          modes: [:commuter_rail]
        }
      ]
      assert actual == expected
    end

    test "ferry groups them by single/multiple trip and groups prices" do
      base = %Fare{name: :ferry, mode: :ferry, duration: :single_trip}
      cheap = %{base | cents: 100}
      expensive = %{base | cents: 200}

      actual = summarize([cheap, expensive], :ferry)
      expected = [
        %Summary{
          name: "One Way",
          duration: :single_trip,
          fares: [{"All Ferry routes", ["$1.00", " - ", "$2.00"]}],
          modes: [:ferry]
        }
      ]
      assert actual == expected
    end
  end

  describe "summarize_one/3" do
    test "single fare is summarized correctly" do
      fare = %Fare{name: {:zone, "6"}, mode: :commuter_rail, duration: :single_trip, cents: 1250, media: :cash}
      summarized = summarize_one(fare, url: "/link_here?please=yes")
      expected = %Summary{
        fares: [{"Cash", "$12.50"}],
        name: ["Zone 6", " ", "One Way"],
        url: "/link_here?please=yes",
        modes: [:commuter_rail],
        duration: :single_trip
      }
      assert summarized == expected
    end
  end
end
