defmodule SiteWeb.FareView.DescriptionTest do
  use ExUnit.Case, async: true
  import SiteWeb.FareView.Description
  alias Fares.Fare
  import IO, only: [iodata_to_binary: 1]

  describe "description/2" do
    test "fare description for one way CR is for commuter rail between the appropriate zones only" do
      fare = %Fare{duration: :single_trip, mode: :commuter_rail, name: {:interzone, "3"}}
      assert fare |> description(%{}) |> iodata_to_binary == "Valid for travel on Commuter Rail between 3 zones outside of Zone 1A only."
    end

    test "fare description for CR round trip is for commuter rail between the appropriate zones only" do
      fare = %Fare{duration: :round_trip, mode: :commuter_rail, name: {:interzone, "3"}}
      assert fare |> description(%{}) |> iodata_to_binary == "Valid for travel on Commuter Rail between 3 zones outside of Zone 1A only."
    end

    test "fare description for month is describes the modes it can be used on" do
      fare = %Fare{name: {:zone, "5"}, duration: :month, mode: :commuter_rail}

      assert fare |> description(%{}) |> iodata_to_binary ==
        "Valid for one calendar month of unlimited travel on Commuter Rail from " <>
        "Zones 1A-5 as well as Local Bus, Subway, and the Charlestown Ferry."
    end

    test "fare description for monthly interzone pass only lists bus in other modes" do
      fare = %Fare{
        name: {:interzone, "5"},
        additional_valid_modes: [:bus],
        duration: :month,
        mode: :commuter_rail
      }

      assert fare |> description(%{}) |> iodata_to_binary ==
        "Valid for one calendar month of unlimited travel on Commuter Rail between " <>
        "5 zones outside of Zone 1A as well as Local Bus."
    end

    test "fare description for month mticket describes where it can be used" do
      fare = %Fare{name: {:zone, "5"}, duration: :month, media: [:mticket], mode: :commuter_rail}

      assert fare |> description(%{}) |> iodata_to_binary ==
        "Valid for one calendar month of travel on the commuter rail from Zones 1A-5 only."
    end

    test "fare description for an inner express bus describes the modes you can use it on with a charlie ticket" do
      result = %Fare{name: :inner_express_bus, duration: :month, media: [:charlie_card, :charlie_ticket]}
               |> description(%{})
               |> List.flatten
      intro = result |> List.first() |> Phoenix.HTML.safe_to_string()
      body = result |> Enum.at(1) |> Phoenix.HTML.safe_to_string()

      assert intro =~ "Unlimited travel for 1 calendar month on:"
      assert body =~ "Inner Express Bus"
      assert body =~ "Subway"
      assert body =~ "Local Bus"
      assert body =~ "Commuter Rail Zone 1A (CharlieTicket or pre-printed CharlieCard with valid date only)"
      assert body =~ "Charlestown Ferry (CharlieTicket or pre-printed CharlieCard with valid date only)"
    end

    test "fare description for an inner express bus describes the modes you can use it on" do
      assert %Fare{name: :inner_express_bus, duration: :month} |> description(%{}) |> iodata_to_binary ==
        "Unlimited travel for one calendar month on the Inner Express Bus, Local Bus, and Subway."
    end

    test "fare description for an outer express bus describes the modes you can use it on with a charlie ticket" do
      result = %Fare{name: :outer_express_bus, duration: :month, media: [:charlie_card, :charlie_ticket]}
               |> description(%{})
               |> List.flatten
      intro = result |> List.first() |> Phoenix.HTML.safe_to_string()
      body = result |> Enum.at(1) |> Phoenix.HTML.safe_to_string()

      assert intro =~ "Unlimited travel for 1 calendar month on:"
      assert body =~ "Inner Express Bus"
      assert body =~ "Subway"
      assert body =~ "Local Bus"
      assert body =~ "Commuter Rail Zone 1A (CharlieTicket or pre-printed CharlieCard with valid date only)"
      assert body =~ "Charlestown Ferry (CharlieTicket or pre-printed CharlieCard with valid date only)"
    end

    test "fare description for an outer express bus describes the modes you can use it on" do
      assert %Fare{name: :outer_express_bus, duration: :month} |> description(%{}) |> iodata_to_binary ==
        "Unlimited travel for one calendar month on the Outer Express Bus as well as the Inner Express Bus, Local Bus, and Subway."
    end

    test "mentions zone 1a fares as part of the description for month passes on subway (regular fare)" do
      fare = %Fare{duration: :month, mode: :subway}
      result = fare |> description(%{}) |> List.flatten()
      body = result |> Enum.at(1) |> Phoenix.HTML.safe_to_string()

      assert body =~ "Commuter Rail Zone 1A (CharlieTicket only)"
    end

    test "mentions zone 1a fares as part of the description for month passes on subway (student fare)" do
      result = %Fare{duration: :month, mode: :subway, reduced: :student}
               |> description(%{})
               |> List.flatten()
      intro = result |> List.first() |> Phoenix.HTML.safe_to_string()
      body = result |> Enum.at(1) |> Phoenix.HTML.safe_to_string()

      assert intro =~ "Unlimited travel for 1 calendar month on:"
      assert body =~ "Subway"
      assert body =~ "Local Bus"
      assert body =~ "Commuter Rail Zone 1A (CharlieTicket only)"
    end

    test "fare description for busses with no media (free fare) do not include transfer info" do
      fare = %Fare{name: :free_fare, duration: :month, mode: :bus, media: []}
      result = fare |> description(%{}) |> iodata_to_binary()

      assert result == "Travel on all local bus routes, SL4 and SL5"
    end

    test "can make a description for every fare" do
      for fare <- Fares.Repo.all() do
        result = description(fare, %{})
        assert result |> Phoenix.HTML.html_escape |> Phoenix.HTML.safe_to_string |> is_binary
      end
    end
  end

  describe "transfers/1" do
    test "if current fare is cheapest, should have costs to other fares" do
      fare = %Fare{mode: :bus, name: :local_bus, duration: :single_trip, media: [:charlie_card], cents: 1}
      result = fare |> transfers |> Enum.at(1) |> Phoenix.HTML.safe_to_string
      assert result =~ "Transfer to subway: $"
      assert result =~ "Transfer to Inner Express Bus: $"
      assert result =~ "Transfer to Outer Express Bus: $"
    end

    test "if current fare is most expensive, should have free transfers to other fares" do
      fare = %Fare{mode: :bus, name: :local_bus, duration: :single_trip, media: [:charlie_card], cents: 40_000}
      result = fare |> transfers |> List.flatten() |> Enum.take(3) |> iodata_to_binary()

      assert result =~ "Includes 1 free transfer to subway, another Local Bus, SL4, or SL5,"
      assert result =~ "Inner Express Bus"
      assert result =~ "Outer Express Bus"
      assert result =~ "within 2 hours of your original ride."
    end

    test "if fare is somewhere in the middle, lists fare differences along with transfers" do
      inner_express_fare = Fares.Repo.all(name: :inner_express_bus, duration: :single_trip, media: [:charlie_card]) |> List.first
      fare = %Fare{mode: :bus, name: :local_bus, duration: :single_trip, media: [:charlie_card], cents: inner_express_fare.cents - 1}

      result = fare |> transfers
      result_1 = result |> Enum.at(0) |> iodata_to_binary()
      result_2 = result |> Enum.at(1) |> Phoenix.HTML.safe_to_string()
      assert result_1 =~ "Includes 1 free transfer to subway, another Local Bus"
      assert result_2 =~ "Transfer to Inner Express Bus: $0.01"
      assert result_2 =~ "Transfer to Outer Express Bus: $1" # leave off cents
    end
  end
end
