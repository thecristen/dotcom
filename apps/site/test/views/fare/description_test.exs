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

  def compact(string) when is_binary(string), do: string
  def compact(list) when is_list(list), do: list |> List.flatten |> Enum.join("")
end
