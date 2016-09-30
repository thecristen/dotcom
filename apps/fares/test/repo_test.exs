defmodule Fares.RepoTest do
  use ExUnit.Case, async: true
  alias Fares.Repo

  describe "filter/1" do
    @fares [
      %Fare{cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket, reduced: nil},
      %Fare{cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket, reduced: :student},
      %Fare{cents: 225, duration: :month, name: :zone_2, pass_type: :ticket, reduced: :student},
      %Fare{cents: 625, duration: :month, name: :zone_3, pass_type: :charlie_card, reduced: nil}
    ]

    test "gives all single trip fares from a list" do
      assert Repo.filter(@fares, duration: :single_trip) == [
        %Fare{cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket, reduced: nil},
        %Fare{cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket, reduced: :student}
      ]
    end

    test "gives all zone 2 fares from a list" do
      assert Repo.filter(@fares, name: :zone_2) == [
        %Fare{cents: 225, duration: :month, name: :zone_2, pass_type: :ticket, reduced: :student}
      ]
    end

    test "gives all student fares from a list" do
      assert Repo.filter(@fares, reduced: :student) == [
        %Fare{cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket, reduced: :student},
        %Fare{cents: 225, duration: :month, name: :zone_2, pass_type: :ticket, reduced: :student},
      ]
    end

    test "gives all ticket fares from a list" do
      assert Repo.filter(@fares, pass_type: :ticket) == [
        %Fare{cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket, reduced: nil},
        %Fare{cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket, reduced: :student},
        %Fare{cents: 225, duration: :month, name: :zone_2, pass_type: :ticket, reduced: :student}
      ]
    end

    test "gives all zone 1a student fares from a list" do
      assert Repo.filter(@fares, [reduced: :student, name: :zone_1a]) == [
        %Fare{cents: 225, duration: :single_trip, name: :zone_1a, pass_type: :ticket, reduced: :student},
      ]
    end
  end
end
