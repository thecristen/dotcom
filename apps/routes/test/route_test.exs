defmodule Routes.RouteTest do
  use ExUnit.Case, async: true
  alias Routes.Route
  import Route

  describe "type_atom/1" do
    test "returns an atom for the route type" do
      for {int, atom} <- [
        {0, :subway},
        {1, :subway},
        {2, :commuter_rail},
        {3, :bus},
        {4, :ferry}
      ] do
        assert type_atom(int) == atom
      end
    end

    test "handles hyphen in commuter-rail" do
      assert type_atom("commuter-rail") == :commuter_rail
      assert type_atom("commuter_rail") == :commuter_rail
    end

    test "extracts the type integer from the route struct and returns the corresponding atom" do
      assert type_atom(%Route{type: 3}) == :bus
    end
  end

  describe "icon_atom/1" do
    test "for subways, returns the name of the line as an atom" do
      for {expected, id} <- [
            red_line: "Red",
            mattapan_line: "Mattapan",
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

  describe "path_atom/1" do
    test "hyphenates the :commuter_rail atom for path usage" do
      assert path_atom(%Route{type: 2}) == :"commuter-rail"
      assert path_atom(%Route{type: 3}) == :bus
    end
  end

  describe "types_for_mode/1" do
    test "returns correct mode list for each mode" do
      assert types_for_mode(:subway) == [0, 1]
      assert types_for_mode(:commuter_rail) == [2]
      assert types_for_mode(:bus) == [3]
      assert types_for_mode(:ferry) == [4]
      for light_rail <- [:green_line, :mattapan_line], do: assert types_for_mode(light_rail) == [0]
      for heavy_rail <- [:red_line, :orange_line, :blue_line], do: assert types_for_mode(heavy_rail) == [1]
    end
  end

  describe "type_name/1" do
    test "titleizes the name" do
      for {atom, str} <- [
        subway: "Subway",
        bus: "Bus",
        ferry: "Ferry",
        commuter_rail: "Commuter Rail",
        the_ride: "The Ride"
      ] do
        assert type_name(atom) == str
      end
    end
  end

  describe "type_summary" do
    test "lists route names for bus routes" do
      routes = [%Route{id: "1", name: "1", type: 3}, %Route{id: "747", name: "SL1", type: 3}]
      assert type_summary(:bus, routes) == "Bus: 1, SL1"
    end

    test "returns type name for all other route types" do
      assert type_summary(:green_line, [%Route{id: "Green-C", name: "Green Line C", type: 0},
                                        %Route{id: "Green-C", name: "Green Line C", type: 0}]) == "Green Line"
      assert type_summary(:mattapan_trolley, [%Route{id: "Mattapan", name: "Mattapan", type: 0}]) == "Mattapan Trolley"
      assert type_summary(:red_line, [%Route{id: "Red", name: "Red Line", type: 1}]) == "Red Line"
      assert type_summary(:commuter_rail, [%Route{id: "CR-Fitchburg", name: "Fitchburg", type: 2}]) == "Commuter Rail"
      assert type_summary(:ferry, [%Route{id: "Boat-F1", name: "Hull Ferry", type: 4}]) == "Ferry"
    end

  end

  describe "direction_name/2" do
    test "returns the name of the direction" do
      assert direction_name(%Route{}, 0) == "Outbound"
      assert direction_name(%Route{}, 1) == "Inbound"
      assert direction_name(%Route{direction_names: %{0 => "Zero"}}, 0) == "Zero"
    end
  end

  describe "vehicle_name/1" do
    test "returns the appropriate type of vehicle" do
      for {type, name} <- [
        {0, "Train"},
        {1, "Train"},
        {2, "Train"},
        {3, "Bus"},
        {4, "Ferry"},
      ] do
        assert vehicle_name(%Route{type: type}) == name
      end
    end
  end

  describe "key_route?" do
    test "extracts the :key_route? boolean" do
      assert key_route?(%Route{key_route?: true})
      refute key_route?(%Route{key_route?: false})
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

  describe "silver line rapid transit routes" do
    test "silver_line_rapid_transit?/1 returns true if a route id is in @silver_line_rapid_transit_routes" do
      assert silver_line_rapid_transit?(sample(silver_line_rapid_transit()))
      refute silver_line_rapid_transit?(%Route{id: "751"})
    end
  end

  describe "silver line airport origin routes" do
    test "inbound routes originating at airport are properly identified" do
      airport_stops =  ["17091", "27092", "17093", "17094", "17095"]
      for origin_id <- airport_stops do
        assert silver_line_airport_stop?(%Route{id: "741"}, origin_id)
      end

      refute silver_line_airport_stop?(%Route{id: "742"}, "17091")
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
