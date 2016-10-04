defmodule FaresTest do
  use ExUnit.Case
  doctest Fares

  test "when the origin is zone 6, finds the zone 6 fares" do
    assert Fares.calculate(:zone_6, :zone_1a) == [
      %Fare{cents: 1000, duration: :single_trip, name: :zone_6,
        pass_type: :ticket, reduced: nil},
      %Fare{cents: 500, duration: :single_trip, name: :zone_6,
        pass_type: :ticket, reduced: :student},
      %Fare{cents: 500, duration: :single_trip, name: :zone_6,
        pass_type: :ticket, reduced: :senior_disabled},
      %Fare{cents: 31800, duration: :month, name: :zone_6,
        pass_type: :ticket, reduced: nil}
    ]
  end

  test "given two stops, finds the interzone fares" do
    assert Fares.calculate(:zone_3, :zone_5) == [
     %Fare{cents: 350, duration: :single_trip, name: :interzone_3,
       pass_type: :ticket, reduced: nil},
     %Fare{cents: 175, duration: :single_trip, name: :interzone_3,
       pass_type: :ticket, reduced: :student},
     %Fare{cents: 175, duration: :single_trip, name: :interzone_3,
       pass_type: :ticket, reduced: :senior_disabled},
     %Fare{cents: 11975, duration: :month, name: :interzone_3, pass_type: :ticket,
       reduced: nil}
    ]
  end

  test "when the origin is zone 1a, finds the fare based on destination" do
    assert Fares.calculate(:zone_1a, :zone_4) == [
      %Fare{cents: 825, duration: :single_trip, name: :zone_4, pass_type: :ticket,
        reduced: nil},
      %Fare{cents: 410, duration: :single_trip, name: :zone_4, pass_type: :ticket,
        reduced: :student},
      %Fare{cents: 410, duration: :single_trip, name: :zone_4, pass_type: :ticket,
        reduced: :senior_disabled},
      %Fare{cents: 26300, duration: :month, name: :zone_4, pass_type: :ticket,
        reduced: nil}
    ]
  end
end
