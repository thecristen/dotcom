defmodule Site.FareViewTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import Site.FareView
  alias Fares.Fare

  test "fare_duration_summary/1" do
    assert fare_duration_summary(:month) == "1 Month"
    assert fare_duration_summary(:round_trip) == "Round Trip"
    assert fare_duration_summary(:single_trip) == "Single Ride"
  end

  describe "eligibility/1" do
    test "returns eligibility information for student fares" do
      assert eligibility(%Fare{mode: :commuter, reduced: :student}) =~
        "Middle and high school students are eligible"
    end

    test "returns eligibility information for senior fares" do
      assert eligibility(%Fare{mode: :commuter, reduced: :senior_disabled}) =~
        "Those who are 65 years of age or older"
    end

    test "returns eligibility information for adult fares" do
      assert eligibility(%Fare{mode: :commuter, reduced: nil}) =~
        "Those who are 12 years of age or older qualify for Adult fare pricing."
    end
  end

  describe "vending_machine_stations/0" do
    test "generates a list of links to stations with fare vending machines" do
      content = vending_machine_stations |> Phoenix.HTML.safe_to_string

      assert content =~ "place-north"
      assert content =~ "place-sstat"
      assert content =~ "place-bbsta"
      assert content =~ "place-brntn"
      assert content =~ "place-forhl"
      assert content =~ "place-jfk"
      assert content =~ "Lynn"
      assert content =~ "place-mlmnl"
      assert content =~ "place-portr"
      assert content =~ "place-qnctr"
      assert content =~ "place-rugg"
      assert content =~ "Worcester"
    end
  end

  describe "charlie_card_stations/0" do
    test "generates a list of links to stations where a customer can buy a CharlieCard" do
      content = charlie_card_stations |> Phoenix.HTML.safe_to_string

      assert content =~ "place-alfcl"
      assert content =~ "place-armnl"
      assert content =~ "place-asmnl"
      assert content =~ "place-bbsta"
      assert content =~ "64000"
      assert content =~ "place-forhl"
      assert content =~ "place-harsq"
      assert content =~ "place-north"
      assert content =~ "place-ogmnl"
      assert content =~ "place-pktrm"
      assert content =~ "place-rugg"
    end
  end
end
