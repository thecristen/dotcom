defmodule Routes.RouteTest do
  use ExUnit.Case, async: true
  alias Routes.Route
  import Route

  describe "icon_atom/1" do
    test "for subways, returns the name of the line as an atom" do
      for {expected, id} <- [
            red_line: "Red",
            red_line: "Mattapan",
            orange_line: "Orange",
            blue_line: "Blue",
            green_line: "Green",
            green_line: "Green-B"] do
          route = %Route{id: id}
          actual = icon_atom(route)
          assert actual == expected
      end
    end

    test "for other routes, returns an atom based on the type" do
      for {expected, type} <- [
            commuter_rail: 2,
            bus: 3,
            ferry: 4] do
          route = %Route{type: type}
          actual = icon_atom(route)
          assert actual == expected
      end
    end
  end
end
