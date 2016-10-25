defmodule Site.FareView.DescriptionTest do
  use ExUnit.Case, async: true
  import Site.FareView.Description
  alias Fares.Fare

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

      assert fare |> description |> compact ==
        "Valid for one calendar month of unlimited travel on Commuter Rail from " <>
        "Zones 1A-5 as well as Local Bus, Subway, Express Bus, and the Charlestown Ferry."
    end

    test "fare description for month mticket describes where it can be used" do
      fare = %Fare{name: {:zone, "5"}, duration: :month, pass_type: :mticket, mode: :commuter}

      assert fare |> description |> compact ==
        "Valid for one calendar month of travel on the commuter rail from Zones 1A-5 only."
    end
  end

  describe "transfers/1" do
    test "if current fare is cheapest, should have costs to other fares" do
      fare = %Fare{mode: :bus, name: :local_bus, duration: :single_trip, pass_type: :charlie_card, cents: 1}
      result = fare |> transfers |> compact
      assert result =~ "Transfer to Subway $"
      assert result =~ "Transfer to Local Bus $"
      assert result =~ "Transfer to Inner Express Bus $"
      assert result =~ "Transfer to Outer Express Bus $"
    end

    test "if current fare is most expensive, should have free transfers to other fares" do
      fare = %Fare{mode: :bus, name: :local_bus, duration: :single_trip, pass_type: :charlie_card, cents: 40000}
      result = fare |> transfers |> compact
      expected = ["Free transfers to Subway",
                  "Local Bus",
                  "Inner Express Bus",
                  "Outer Express Bus."
                 ] |> AndJoin.join |> compact
      assert result == expected
    end

    test "if fare is somewhere in the middle, lists fare differences along with transfers" do
      inner_express_fare = Fares.Repo.all(name: :inner_express_bus, duration: :single_trip, pass_type: :charlie_card) |> List.first
      fare = %Fare{mode: :bus, name: :local_bus, duration: :single_trip, pass_type: :charlie_card, cents: inner_express_fare.cents - 1}

      result = fare |> transfers |> compact
      assert result =~ "Transfer to Inner Express Bus $0.01."
      assert result =~ "Transfer to Outer Express Bus $1" # leave off cents
      assert result =~ "Free transfers to Subway and Local Bus."
    end
  end

  def compact(string) when is_binary(string), do: string
  def compact(list) when is_list(list), do: list |> List.flatten |> Enum.join("")
end
