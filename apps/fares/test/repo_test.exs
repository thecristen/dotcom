defmodule Fares.RepoTest do
  use ExUnit.Case, async: true
  alias Fares.{Repo, Fare}

  describe "filter/1" do
    @fares [
      %Fare{mode: :commuter, cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket, reduced: nil},
      %Fare{mode: :commuter, cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket,
            reduced: :student},
      %Fare{mode: :commuter, cents: 225, duration: :month, name: :zone_2, pass_type: :ticket, reduced: :student},
      %Fare{mode: :commuter, cents: 625, duration: :month, name: :zone_3, pass_type: :charlie_card, reduced: nil},
      %Fare{mode: :subway, cents: 225, duration: :single_trip, name: :subway_charlie_card, pass_type: :charlie_card,
            reduced: nil},
      %Fare{mode: :subway, cents: 275, duration: :single_trip, name: :subway_ticket, pass_type: :ticket, reduced: nil},
      %Fare{mode: :subway, cents: 3000, duration: :month, name: :subway_student, pass_type: :charlie_card,
            reduced: :student}
    ]

    test "gives all single trip fares from a list" do
      assert Repo.filter(@fares, duration: :single_trip) == [
        %Fare{mode: :commuter, cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket, reduced: nil},
        %Fare{mode: :commuter, cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket,
              reduced: :student},
        %Fare{mode: :subway, cents: 225, duration: :single_trip, name: :subway_charlie_card, pass_type: :charlie_card,
              reduced: nil},
        %Fare{mode: :subway, cents: 275, duration: :single_trip, name: :subway_ticket, pass_type: :ticket, reduced: nil}
      ]
    end

    test "gives all zone 2 fares from a list" do
      assert Repo.filter(@fares, name: :zone_2) == [
        %Fare{mode: :commuter, cents: 225, duration: :month, name: :zone_2, pass_type: :ticket, reduced: :student}
      ]
    end

    test "gives all student fares from a list" do
      assert Repo.filter(@fares, reduced: :student) == [
        %Fare{mode: :commuter, cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket,
              reduced: :student},
        %Fare{mode: :commuter, cents: 225, duration: :month, name: :zone_2, pass_type: :ticket, reduced: :student},
        %Fare{mode: :subway, cents: 3000, duration: :month, name: :subway_student, pass_type: :charlie_card,
              reduced: :student}
      ]
    end

    test "gives all ticket fares from a list" do
      assert Repo.filter(@fares, pass_type: :ticket) == [
        %Fare{mode: :commuter, cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket, reduced: nil},
        %Fare{mode: :commuter, cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket,
              reduced: :student},
        %Fare{mode: :commuter, cents: 225, duration: :month, name: :zone_2, pass_type: :ticket, reduced: :student},
        %Fare{mode: :subway, cents: 275, duration: :single_trip, name: :subway_ticket, pass_type: :ticket, reduced: nil}
      ]
    end

    test "gives all zone 1a student fares from a list" do
      assert Repo.filter(@fares, [reduced: :student, name: :zone_1a]) == [
        %Fare{mode: :commuter, cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket,
              reduced: :student},
      ]
    end

    test "can filter by mode" do
      assert Repo.filter(@fares, mode: :subway) == [
        %Fare{mode: :subway, cents: 225, duration: :single_trip, name: :subway_charlie_card, pass_type: :charlie_card,
              reduced: nil},
        %Fare{mode: :subway, cents: 275, duration: :single_trip, name: :subway_ticket, pass_type: :ticket,
              reduced: nil},
        %Fare{mode: :subway, cents: 3000, duration: :month, name: :subway_student, pass_type: :charlie_card,
              reduced: :student}
      ]
    end
  end
end
