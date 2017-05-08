defmodule Stops.RouteStopsTest do
  use ExUnit.Case
  alias Stops.{RouteStops}

  @red %Routes.Route{id: "Red", type: 1}

  describe "get_shapes/3" do
    test "for red line, direction: 0" do
      shapes = "Red"
      |> Routes.Repo.get_shapes(0)
      |> RouteStops.get_shapes(@red, 0)
      assert [%Routes.Shape{name: "Ashmont", stop_ids: ashmont_stops}, %Routes.Shape{name: "Braintree", stop_ids: braintree_stops}] = shapes
      first_stops = [ashmont_stops, braintree_stops] |> Enum.map(& &1 |> List.first())
      last_stops = [ashmont_stops, braintree_stops] |> Enum.map(& &1 |> List.last())
      assert first_stops == ["place-alfcl", "place-alfcl"]
      assert last_stops == ["place-asmnl", "place-brntn"]
      refute List.last(ashmont_stops) in braintree_stops
      refute List.last(braintree_stops) in ashmont_stops
    end

    test "for red line, direction: 1" do
      shapes = "Red"
      |> Routes.Repo.get_shapes(1)
      |> RouteStops.get_shapes(@red, 1)

      assert [%Routes.Shape{name: "Ashmont", stop_ids: ashmont_stops}, %Routes.Shape{name: "Braintree", stop_ids: braintree_stops}] = shapes
      first_stops = [ashmont_stops, braintree_stops] |> Enum.map(& &1 |> List.first())
      last_stops = [ashmont_stops, braintree_stops] |> Enum.map(& &1 |> List.last())
      assert first_stops == ["place-asmnl", "place-brntn"]
      assert last_stops == ["place-alfcl", "place-alfcl"]
    end

    test "for green line, direction: 0" do
      [b_shapes, c_shapes, d_shapes, e_shapes] = ["Green-B", "Green-C", "Green-D", "Green-E"]
      |> Task.async_stream(fn id -> Routes.Repo.get_shapes(id, 0) end)
      |> Enum.map(fn {:ok, shapes} -> shapes end)
      assert [%Routes.Shape{name: "Boston College", stop_ids: b_stops}] = RouteStops.get_shapes(b_shapes, %Routes.Route{id: "Green-B", type: 0}, 0)
      assert [%Routes.Shape{name: "Cleveland Circle", stop_ids: c_stops}] = RouteStops.get_shapes(c_shapes, %Routes.Route{id: "Green-C", type: 0}, 0)
      assert [%Routes.Shape{name: "Riverside", stop_ids: d_stops}] = RouteStops.get_shapes(d_shapes, %Routes.Route{id: "Green-D", type: 0}, 0)
      assert [%Routes.Shape{name: "Heath Street", stop_ids: e_stops}] = RouteStops.get_shapes(e_shapes, %Routes.Route{id: "Green-E", type: 0}, 0)

      first_stops = [b_stops, c_stops, d_stops, e_stops]
      |> Enum.map(&List.first/1)
      |> Task.async_stream(&Stops.Api.by_gtfs_id/1)
      |> Enum.map(fn {:ok, stop} -> stop.id end)

      last_stops = [b_stops, c_stops, d_stops, e_stops]
      |> Enum.map(&List.last/1)
      |> Task.async_stream(&Stops.Api.by_gtfs_id/1)
      |> Enum.map(fn {:ok, stop} -> stop.id end)

      assert first_stops == ["place-pktrm", "place-north", "place-gover", "place-lech"]
      assert last_stops == ["place-lake", "place-clmnl", "place-river", "place-hsmnl"]
    end

    test "for bus with variation" do
      assert [%Routes.Shape{name: outbound_name, stop_ids: outbound_stops}] = "47" |> Routes.Repo.get_shapes(0) |> RouteStops.get_shapes(%Routes.Route{id: "47", type: 3}, 0)
      assert outbound_name == "Central Square, Cambridge via Longwood & Boston Medical Center"
      first_last = [List.first(outbound_stops), List.last(outbound_stops)] |> Task.async_stream(&Stops.Api.by_gtfs_id/1) |> Enum.map(fn {:ok, stop} -> stop.name end)
      assert first_last == ["88 E Newton St", "Green St @ Magazine St"]
      assert [%Routes.Shape{name: inbound_name, stop_ids: inbound_stops}] = "47" |> Routes.Repo.get_shapes(1) |> RouteStops.get_shapes(%Routes.Route{id: "47", type: 3}, 1)
      assert inbound_name == "Boston Medical Center via Dudley Station"
      first_last = [List.first(inbound_stops), List.last(inbound_stops)] |> Task.async_stream(&Stops.Api.by_gtfs_id/1) |> Enum.map(fn {:ok, stop} -> stop.name end)
      assert first_last == ["Massachusetts Ave @ Pearl St", "88 E Newton St"]
    end
  end

  describe "by_direction/2 returns a list of stops in one direction in the correct order" do
    test "for Red Line direction: 1" do
      stops = Stops.Repo.by_route("Red", 0)
      shapes = Routes.Repo.get_shapes("Red", 0)
      stops = RouteStops.by_direction(stops, shapes, @red, 0)
      assert [%Stops.RouteStops{branch: nil, stops: unbranched_stops}|_] = stops
      assert %Stops.RouteStops{branch: "Braintree", stops: braintree_stops} = Enum.at(stops, 1)
      assert %Stops.RouteStops{branch: "Ashmont", stops: ashmont_stops} = List.last(stops)


      assert unbranched_stops |> Enum.map(& &1.name) == ["Alewife", "Davis", "Porter", "Harvard", "Central",
        "Kendall/MIT", "Charles/MGH", "Park Street", "Downtown Crossing", "South Station", "Broadway", "Andrew", "JFK/Umass"]

      [alewife | _] = unbranched_stops
      assert alewife.is_terminus? == true
      assert alewife.zone == nil
      assert alewife.branch == nil
      assert alewife.stop_features == [:bus, :access]
      assert alewife.stop_number == %{0 => 0}

      jfk = List.last(unbranched_stops)
      assert jfk.name == "JFK/Umass"
      assert jfk.branch == nil
      assert jfk.stop_features == [:commuter_rail, :bus, :access]
      assert jfk.is_terminus? == false
      assert jfk.stop_number == %{0 => 12}

      assert [savin|_] = ashmont_stops
      assert savin.name == "Savin Hill"
      assert savin.branch == "Ashmont"
      assert savin.stop_features == [:access]
      assert savin.is_terminus? == false
      assert savin.stop_number == %{0 => 13}

      ashmont = List.last(ashmont_stops)
      assert ashmont.name == "Ashmont"
      assert ashmont.branch == "Ashmont"
      assert ashmont.stop_features == [:bus, :access]
      assert ashmont.is_terminus? == true
      assert ashmont.stop_number == %{0 => 16}

      [north_quincy|_] = braintree_stops
      assert north_quincy.name == "North Quincy"
      assert north_quincy.branch == "Braintree"
      assert north_quincy.stop_features == [:bus, :access]
      assert north_quincy.is_terminus? == false
      assert north_quincy.stop_number == %{0 => 13}

      braintree = List.last(braintree_stops)
      assert braintree.name == "Braintree"
      assert braintree.branch == "Braintree"
      assert braintree.stop_features == [:commuter_rail, :bus, :access]
      assert braintree.is_terminus? == true
      assert braintree.stop_number == %{0 => 17}
    end

    test "for Red Line, direction: 1" do
      stops = Stops.Repo.by_route("Red", 1)
      shapes = Routes.Repo.get_shapes("Red", 1)
      stops = RouteStops.by_direction(stops, shapes, @red, 1)

      assert [%Stops.RouteStops{branch: "Ashmont", stops: ashmont_stops}|_] = stops
      assert %Stops.RouteStops{branch: "Braintree", stops: braintree_stops} = Enum.at(stops, 1)
      assert %Stops.RouteStops{branch: nil, stops: _unbranched_stops} = List.last(stops)

      [ashmont|_] = ashmont_stops
      assert ashmont.name == "Ashmont"
      assert ashmont.branch == "Ashmont"
      assert ashmont.is_terminus? == true
      assert ashmont.stop_number == %{1 => 0}

      savin = List.last(ashmont_stops)
      assert savin.name == "Savin Hill"
      assert savin.branch == "Ashmont"
      assert savin.is_terminus? == false
      assert savin.stop_number == %{1 => 3}

      [braintree|_] = braintree_stops
      assert braintree.name == "Braintree"
      assert braintree.branch == "Braintree"
      assert braintree.stop_features == [:commuter_rail, :bus, :access]
      assert braintree.is_terminus? == true
      assert braintree.stop_number == %{1 => 0}

      n_quincy = List.last(braintree_stops)
      assert n_quincy.name == "North Quincy"
      assert n_quincy.branch == "Braintree"
      assert n_quincy.is_terminus? == false
      assert n_quincy.stop_number == %{1 => 4}
    end

    test "works for green E line" do
      route = %Routes.Route{id: "Green-E", type: 0}
      shapes = Routes.Repo.get_shapes("Green-E", 0)
      stops = Stops.Repo.by_route("Green-E", 0)
      stops = RouteStops.by_direction(stops, shapes, route, 0)

      assert [%Stops.RouteStops{branch: "Heath Street", stops: [%Stops.RouteStop{id: "place-lech", is_terminus?: true}|_]}] = stops
    end

    test "works for green non-E line" do
      route = %Routes.Route{id: "Green-B", type: 0}
      shapes = Routes.Repo.get_shapes("Green-B", 0)
      stops = Stops.Repo.by_route("Green-B", 0)
      stops = RouteStops.by_direction(stops, shapes, route, 0)

      assert [%Stops.RouteStops{branch: "Boston College", stops: [%Stops.RouteStop{id: "place-pktrm", is_terminus?: true}|_] = b_stops}] = stops
      assert %Stops.RouteStop{id: "place-lake", is_terminus?: true} = List.last(b_stops)
    end


    test "works for Kingston line" do
      route = %Routes.Route{id: "CR-Kingston", type: 2}
      shapes = Routes.Repo.get_shapes("CR-Kingston", 0)
      stops = Stops.Repo.by_route("CR-Kingston", 0)
      stops = RouteStops.by_direction(stops, shapes, route, 0)

      assert [%Stops.RouteStops{branch: nil, stops: [%Stops.RouteStop{id: "place-sstat"}|_unbranched_stops]}|_] = stops
      assert %Stops.RouteStops{branch: "Plymouth", stops: [%Stops.RouteStop{id: "Plymouth"}]} = Enum.at(stops, 1)
      assert %Stops.RouteStops{branch: "Kingston", stops: [%Stops.RouteStop{id: "Kingston"}]} = List.last(stops)
    end

    test "works for bus routes" do
      stops = Stops.Repo.by_route("1", 0)
      shapes = Routes.Repo.get_shapes("1", 0)
      route = %Routes.Route{id: "1", type: 3}
      [%Stops.RouteStops{branch: "Harvard", stops: outbound}] = RouteStops.by_direction(stops, shapes, route, 0)
      assert is_list(outbound)
      assert Enum.all?(outbound, & &1.branch == "Harvard")
      assert outbound |> List.first() |> Map.get(:is_terminus?) == true
      assert outbound |> Enum.slice(1..-2) |> Enum.all?(& &1.is_terminus? == false)

      stops = Stops.Repo.by_route("1", 1)
      shapes = Routes.Repo.get_shapes("1", 1)
      route = %Routes.Route{id: "1", type: 3}

      [%Stops.RouteStops{branch: "Dudley", stops: inbound}] = RouteStops.by_direction(stops, shapes, route, 1)
      assert Enum.all?(inbound, & &1.branch == "Dudley")
      assert inbound |> List.first() |> Map.get(:is_terminus?) == true
    end

    test "works for ferry routes" do
      stops = Stops.Repo.by_route("Boat-F4", 0)
      shapes = Routes.Repo.get_shapes("Boat-F4", 0)
      route = %Routes.Route{id: "Boat-F4", type: 4}
      [%Stops.RouteStops{branch: "Boat-Charlestown", stops: stops}] = RouteStops.by_direction(stops, shapes, route, 0)

      assert Enum.all?(stops, & &1.__struct__ == Stops.RouteStop)
    end
  end
end
