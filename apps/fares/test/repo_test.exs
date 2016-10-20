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

  describe "mapper/1" do
    test "maps the fares for a zone into one way and round trip tickets, and monthly ticket and mticket prices" do
      assert Repo.ZoneFares.mapper(["commuter", "zone_1a","2.25","1.10","84.50"]) == [
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
