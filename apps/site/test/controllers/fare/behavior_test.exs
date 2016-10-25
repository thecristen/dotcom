defmodule Site.FareController.BehaviorTest do
  use ExUnit.Case, async: true

  alias Fares.Fare
  alias Site.FareController.Filter
  import Site.FareController.Behavior

  describe "filter_reduced/2" do
    @fares [%Fare{name: {:zone, "6"}, reduced: nil},
            %Fare{name: {:zone, "5"}, reduced: nil},
            %Fare{name: {:zone, "6"}, reduced: :student}]

    test "filters out non-adult fares" do
      expected_fares = [%Fare{name: {:zone, "6"}, reduced: nil},
                        %Fare{name: {:zone, "5"}, reduced: nil}]
      assert filter_reduced(@fares, nil) == expected_fares
    end

    test "filters out non-student fares" do
      expected_fares = [%Fare{name: {:zone, "6"}, reduced: :student}]
      assert filter_reduced(@fares, :student) == expected_fares
    end
  end

  describe "selected_filter" do
    @filters [
      %Filter{id: "1"},
      %Filter{id: "2"}
    ]

    test "defaults to returning the first filter" do
      assert selected_filter(@filters, nil) == List.first(@filters)
      assert selected_filter(@filters, "unknown") == List.first(@filters)
    end

    test "returns the filter based on the id" do
      assert selected_filter(@filters, "1") == List.first(@filters)
      assert selected_filter(@filters, "2") == List.last(@filters)
    end

    test "if there are no filters, return nil" do
      assert selected_filter([], "1") == nil
    end
  end
end
