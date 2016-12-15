defmodule FaresTest do
  use ExUnit.Case, async: true
  doctest Fares

  test "when the origin is zone 6, finds the zone 6 fares" do
    assert Fares.calculate("6", "1A") == {:zone, "6"}
  end

  test "given two stops, finds the interzone fares" do
    assert Fares.calculate("3", "5") == {:interzone, "3"}
  end

  test "when the origin is zone 1a, finds the fare based on destination" do
    assert Fares.calculate("1A", "4") == {:zone, "4"}
  end

end
