defmodule Routes.RouteTest do
  use ExUnit.Case, async: true
  alias Routes.Route
  import Route

  describe "icon_atom/1" do
    test "for subways, returns the name of the line as an atom" do
      for {expected, id} <- [
            red_line: "Red",
            mattapan_trolley: "Mattapan",
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

  describe "types_for_mode/1" do
    test "returns correct mode list for each mode" do
      assert types_for_mode(:subway) == [0, 1]
      assert types_for_mode(:commuter_rail) == [2]
      assert types_for_mode(:bus) == [3]
      assert types_for_mode(:ferry) == [4]
    end
  end

  describe "express routes" do
    defp sample(routes) do
      routes
      |> Enum.shuffle
      |> Enum.at(0)
      |> (fn id -> %Route{id: id} end).()
    end

    test "inner_express?/1 returns true if a route id is in @inner_express_routes" do
      assert inner_express?(sample(inner_express()))
      refute inner_express?(sample(outer_express()))
      refute inner_express?(%Route{id: "1"})
    end

    test "outer_express?/1 returns true if a route id is in @outer_express_routes" do
      assert outer_express?(sample(outer_express()))
      refute outer_express?(sample(inner_express()))
      refute outer_express?(%Route{id: "1"})
    end
  end

  describe "Phoenix.Param.to_param" do
    test "Green routes are normalized to Green" do
      green_e = %Route{id: "Green-E"}
      green_b = %Route{id: "Green-B"}
      green_c = %Route{id: "Green-C"}
      green_d = %Route{id: "Green-D"}
      to_param = &Phoenix.Param.Routes.Route.to_param/1
      for route <- [green_e, green_b, green_c, green_d] do
        assert to_param.(route) == "Green"
      end
    end

    test "Mattapan is kept as mattapan" do
      mattapan = %Route{id: "Mattapan"}
      assert Phoenix.Param.Routes.Route.to_param(mattapan) == "Mattapan"
    end
  end
end
