defmodule Fares.FareInfoTest do
  use ExUnit.Case, async: true
  alias Fares.Fare
  import Fares.FareInfo

  describe "mapper/1" do
    test "maps the fares for a zone into one way and round trip tickets, and monthly ticket and mticket prices" do
      assert mapper(["commuter", "zone_1a","2.25","1.10","84.50"]) == [
        %Fare{
          name: {:zone, "1A"},
          mode: :commuter,
          duration: :single_trip,
          pass_type: :ticket,
          reduced: nil,
          cents: 225},
        %Fare{
          name: {:zone, "1A"},
          mode: :commuter,
          duration: :single_trip,
          pass_type: :student_card,
          reduced: :student,
          cents: 110},
        %Fare{
          name: {:zone, "1A"},
          mode: :commuter,
          duration: :single_trip,
          pass_type: :senior_card,
          reduced: :senior_disabled,
          cents: 110},
        %Fare{
          name: {:zone, "1A"},
          mode: :commuter,
          duration: :round_trip,
          pass_type: :ticket,
          reduced: nil,
          cents: 450},
        %Fare{
          name: {:zone, "1A"},
          mode: :commuter,
          duration: :round_trip,
          pass_type: :student_card,
          reduced: :student,
          cents: 220},
        %Fare{
          name: {:zone, "1A"},
          mode: :commuter,
          duration: :round_trip,
          pass_type: :senior_card,
          reduced: :senior_disabled,
          cents: 220},
        %Fare{
          name: {:zone, "1A"},
          mode: :commuter,
          duration: :month,
          pass_type: :ticket,
          reduced: nil,
          cents: 8450,
          additional_valid_modes: [:subway, :bus, :ferry]},
        %Fare{
          name: {:zone, "1A"},
          mode: :commuter,
          duration: :month,
          pass_type: :mticket,
          reduced: nil,
          cents: 7450},
      ]
    end
  end
end
