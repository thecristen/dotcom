defmodule Site.ScheduleV2Controller.LineTest do
  use Site.ConnCase, async: true
  import Site.ScheduleV2Controller.Line
  alias Stops.{RouteStop, RouteStops}

  doctest Site.ScheduleV2Controller.Line

  describe "get_branches" do
    test "returns RouteStops for all green line branches in reverse order when direction is 0" do
      shapes = get_all_shapes("Green", 0)
      result = get_branches(shapes, nil, %Routes.Route{id: "Green"}, 0)
      assert Enum.map(result, & &1.branch) == ["Green-E", "Green-D", "Green-C", "Green-B"]
    end
  end

  describe "build_stop_list/2 for Green Line" do
    test "direction 0 returns a list of all stops in order from east to west" do
      [lechmere, science_park, north_station, haymarket, gvt_ctr, park, boylston,
       arlington, copley, heath_st, hynes, kenmore, riverside, cleveland_cir, boston_college] = "Green"
      |> get_all_shapes(0)
      |> get_branches([], %Routes.Route{id: "Green"}, 0)
      |> remove_collapsed_stops(nil, 0)
      |> build_stop_list(0)
      |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      assert lechmere ==       {[{"Green-B", :empty}, {"Green-C", :empty}, {"Green-D", :empty}, {"Green-E", :terminus}], "place-lech"}
      assert science_park ==   {[{"Green-B", :empty}, {"Green-C", :empty}, {"Green-D", :empty}, {"Green-E", :stop}], "place-spmnl"}
      assert north_station ==  {[{"Green-B", :empty}, {"Green-C", :terminus}, {"Green-D", :empty}, {"Green-E", :stop}], "place-north"}
      assert haymarket ==      {[{"Green-B", :empty}, {"Green-C", :stop}, {"Green-D", :empty}, {"Green-E", :stop}], "place-haecl"}
      assert gvt_ctr ==        {[{"Green-B", :empty}, {"Green-C", :stop}, {"Green-D", :terminus}, {"Green-E", :stop}], "place-gover"}
      assert park ==           {[{"Green-B", :terminus}, {"Green-C", :stop}, {"Green-D", :stop}, {"Green-E", :stop}], "place-pktrm"}
      assert boylston ==       {[{"Green-B", :stop}, {"Green-C", :stop}, {"Green-D", :stop}, {"Green-E", :stop}], "place-boyls"}
      assert arlington ==      {[{"Green-B", :stop}, {"Green-C", :stop}, {"Green-D", :stop}, {"Green-E", :stop}], "place-armnl"}
      assert copley ==         {[{"Green-B", :stop}, {"Green-C", :stop}, {"Green-D", :stop}, {"Green-E", :stop}], "place-coecl"}
      assert heath_st ==       {[{"Green-B", :line}, {"Green-C", :line}, {"Green-D", :line}, {"Green-E", :terminus}], "place-hsmnl"}
      assert hynes ==          {[{"Green-B", :stop}, {"Green-C", :stop}, {"Green-D", :stop}], "place-hymnl"}
      assert kenmore ==        {[{"Green-B", :stop}, {"Green-C", :stop}, {"Green-D", :stop}], "place-kencl"}
      assert riverside ==      {[{"Green-B", :line}, {"Green-C", :line}, {"Green-D", :terminus}], "place-river"}
      assert cleveland_cir ==  {[{"Green-B", :line}, {"Green-C", :terminus}], "place-clmnl"}
      assert boston_college == {[{"Green-B", :terminus}], "place-lake"}
    end

    test "direction 1 returns a list of all stops in order from west to east" do
      [boston_college, cleveland_circle, riverside, kenmore, hynes, heath_st, copley, arlington,
       boylston, park, gvt_ctr, haymarket, north_station, science_park, lechmere] = "Green"
      |> get_all_shapes(1)
      |> get_branches([], %Routes.Route{id: "Green"}, 1)
      |> remove_collapsed_stops(nil, 1)
      |> build_stop_list(1)
      |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      assert boston_college   == {[{"Green-B", :terminus}], "place-lake"}
      assert cleveland_circle == {[{"Green-B", :line}, {"Green-C", :terminus}], "place-clmnl"}
      assert riverside        == {[{"Green-B", :line}, {"Green-C", :line}, {"Green-D", :terminus}], "place-river"}
      assert kenmore          == {[{"Green-B", :stop}, {"Green-C", :stop}, {"Green-D", :stop}], "place-kencl"}
      assert hynes            == {[{"Green-B", :stop}, {"Green-C", :stop}, {"Green-D", :stop}], "place-hymnl"}
      assert heath_st         == {[{"Green-B", :line}, {"Green-C", :line}, {"Green-D", :line}, {"Green-E", :terminus}], "place-hsmnl"}
      assert copley           == {[{"Green-B", :stop}, {"Green-C", :stop}, {"Green-D", :stop}, {"Green-E", :stop}], "place-coecl"}
      assert arlington        == {[{"Green-B", :stop}, {"Green-C", :stop}, {"Green-D", :stop}, {"Green-E", :stop}], "place-armnl"}
      assert boylston         == {[{"Green-B", :stop}, {"Green-C", :stop}, {"Green-D", :stop}, {"Green-E", :stop}], "place-boyls"}
      assert park             == {[{"Green-B", :terminus}, {"Green-C", :stop}, {"Green-D", :stop}, {"Green-E", :stop}], "place-pktrm"}
      assert gvt_ctr          == {[{"Green-B", :empty}, {"Green-C", :stop}, {"Green-D", :terminus}, {"Green-E", :stop}], "place-gover"}
      assert haymarket        == {[{"Green-B", :empty}, {"Green-C", :stop}, {"Green-D", :empty}, {"Green-E", :stop}], "place-haecl"}
      assert north_station    == {[{"Green-B", :empty}, {"Green-C", :terminus}, {"Green-D", :empty}, {"Green-E", :stop}], "place-north"}
      assert science_park     == {[{"Green-B", :empty}, {"Green-C", :empty}, {"Green-D", :empty}, {"Green-E", :stop}], "place-spmnl"}
      assert lechmere         == {[{"Green-B", :empty}, {"Green-C", :empty}, {"Green-D", :empty}, {"Green-E", :terminus}], "place-lech"}
    end
  end

  describe "build_stop_list/2 for branched non-Green routes" do
    test "Red outbound" do
      [alewife, davis, porter, harvard, central, kendall, charles,
       park, dtx, sstat, broadway, andrew, jfk, braintree, ashmont] = "Red"
      |> get_all_shapes(0)
      |> get_branches([], %Routes.Route{id: "Red"}, 0)
      |> remove_collapsed_stops(nil, 0)
      |> build_stop_list(0)
      |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      assert alewife     == {[{nil, :terminus}], "place-alfcl"}
      assert davis       == {[{nil, :stop}], "place-davis"}
      assert porter      == {[{nil, :stop}], "place-portr"}
      assert harvard     == {[{nil, :stop}], "place-harsq"}
      assert central     == {[{nil, :stop}], "place-cntsq"}
      assert kendall     == {[{nil, :stop}], "place-knncl"}
      assert charles     == {[{nil, :stop}], "place-chmnl"}
      assert park        == {[{nil, :stop}], "place-pktrm"}
      assert dtx         == {[{nil, :stop}], "place-dwnxg"}
      assert sstat       == {[{nil, :stop}], "place-sstat"}
      assert broadway    == {[{nil, :stop}], "place-brdwy"}
      assert andrew      == {[{nil, :stop}], "place-andrw"}
      assert jfk         == {[{"Ashmont", :merge}, {"Braintree", :merge}], "place-jfk"}
      assert braintree   == {[{"Ashmont", :line}, {"Braintree", :terminus}], "place-brntn"}
      assert ashmont     == {[{"Ashmont", :terminus}], "place-asmnl"}
    end

    test "Red inbound" do
      [ashmont, braintree, jfk, andrew, broadway, sstat, dtx, park,
       charles, kendall, central, harvard, porter, davis, alewife] = "Red"
      |> get_all_shapes(1)
      |> get_branches([], %Routes.Route{id: "Red"}, 1)
      |> remove_collapsed_stops(nil, 1)
      |> build_stop_list(1)
      |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      assert ashmont   == {[{"Ashmont", :terminus}], "place-asmnl"}
      assert braintree == {[{"Ashmont", :line}, {"Braintree", :terminus}], "place-brntn"}
      assert jfk       == {[{"Ashmont", :merge}, {"Braintree", :merge}], "place-jfk"}
      assert andrew    == {[{nil, :stop}], "place-andrw"}
      assert broadway  == {[{nil, :stop}], "place-brdwy"}
      assert sstat     == {[{nil, :stop}], "place-sstat"}
      assert dtx       == {[{nil, :stop}], "place-dwnxg"}
      assert park      == {[{nil, :stop}], "place-pktrm"}
      assert charles   == {[{nil, :stop}], "place-chmnl"}
      assert kendall   == {[{nil, :stop}], "place-knncl"}
      assert central   == {[{nil, :stop}], "place-cntsq"}
      assert harvard   == {[{nil, :stop}], "place-harsq"}
      assert porter    == {[{nil, :stop}], "place-portr"}
      assert davis     == {[{nil, :stop}], "place-davis"}
      assert alewife   == {[{nil, :terminus}], "place-alfcl"}
    end

    test "CR-Providence outbound" do
      [sstat, back_bay, ruggles, hyde_park, route_128,
       canton_jnct, stoughton, wickford_jnct] = "CR-Providence"
      |> get_all_shapes(0)
      |> get_branches([], %Routes.Route{id: "CR-Providence"}, 0)
      |> remove_collapsed_stops(nil, 0)
      |> build_stop_list(0)
      |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      assert sstat         == {[{nil, :terminus}], "place-sstat"}
      assert back_bay      == {[{nil, :stop}], "place-bbsta"}
      assert ruggles       == {[{nil, :stop}], "place-rugg"}
      assert hyde_park     == {[{nil, :stop}], "Hyde Park"}
      assert route_128     == {[{nil, :stop}], "Route 128"}
      assert canton_jnct   == {[{"Providence", :merge}, {"Stoughton", :merge}], "Canton Junction"}
      assert stoughton     == {[{"Providence", :line}, {"Stoughton", :terminus}], "Stoughton"}
      assert wickford_jnct == {[{"Providence", :terminus}], "Wickford Junction"}
    end

    test "CR-Providence inbound" do
      [wickford_jnct, stoughton, canton_jnct, route_128,
       hyde_park, ruggles, back_bay, sstat] = "CR-Providence"
      |> get_all_shapes(1)
      |> get_branches([], %Routes.Route{id: "CR-Providence"}, 1)
      |> remove_collapsed_stops(nil, 1)
      |> build_stop_list(1)
      |> Enum.map(fn {branches, stop} -> {branches, stop.id} end)

      assert sstat         == {[{nil, :terminus}], "place-sstat"}
      assert back_bay      == {[{nil, :stop}], "place-bbsta"}
      assert ruggles       == {[{nil, :stop}], "place-rugg"}
      assert hyde_park     == {[{nil, :stop}], "Hyde Park"}
      assert route_128     == {[{nil, :stop}], "Route 128"}
      assert canton_jnct   == {[{"Wickford Junction", :merge}, {"Stoughton", :merge}], "Canton Junction"}
      assert stoughton     == {[{"Wickford Junction", :line}, {"Stoughton", :terminus}], "Stoughton"}
      assert wickford_jnct == {[{"Wickford Junction", :terminus}], "Wickford Junction"}

    end
  end

  describe "stop_bubble_type/2" do
    test "copley" do
      stop = %RouteStop{id: "place-coecl"}
      assert stop_bubble_type("Green-B", stop) == {"Green-B", :stop}
      assert stop_bubble_type("Green-C", stop) == {"Green-C", :stop}
      assert stop_bubble_type("Green-D", stop) == {"Green-D", :stop}
      assert stop_bubble_type("Green-E", stop) == {"Green-E", :stop}
    end
  end

  describe "build_branched_stop" do
    test "lechmere" do
      stop = %RouteStop{id: "place-lech"}
      branches = {nil, GreenLine.branch_ids()}
      bubbles = [{"Green-B", :empty}, {"Green-C", :empty}, {"Green-D", :empty}, {"Green-E", :terminus}]
      assert build_branched_stop(stop, [], branches) == [{bubbles, stop}]
    end

    test "park" do
      stop = %RouteStop{id: "place-pktrm"}
      branches = {nil, GreenLine.branch_ids()}
      bubbles = [{"Green-B", :terminus}, {"Green-C", :stop}, {"Green-D", :stop}, {"Green-E", :stop}]
      assert build_branched_stop(stop, [], branches) == [{bubbles, stop}]
    end

    test "copley" do
      stop = %RouteStop{id: "place-coecl"}
      branches = {nil, GreenLine.branch_ids()}
      bubbles = [{"Green-B", :stop}, {"Green-C", :stop}, {"Green-D", :stop}, {"Green-E", :stop}]
      assert build_branched_stop(stop, [], branches) == [{bubbles, stop}]
    end

    test "heath st" do
      assert GreenLine.terminus?("place-hsmnl", "Green-E")
      stop = %RouteStop{id: "place-hsmnl", branch: "Green-E", is_terminus?: true}
      branches = {nil, GreenLine.branch_ids()}
      bubbles = [{"Green-B", :line}, {"Green-C", :line}, {"Green-D", :line}, {"Green-E", :terminus}]
      assert build_branched_stop(stop, [], branches) == [{bubbles, stop}]
    end

    test "a terminus that's not on a branch is always a terminus" do
      stop = %RouteStop{id: "new", branch: nil, is_terminus?: true}
      assert build_branched_stop({stop, true}, [], {nil, []}) == [{[{nil, :terminus}], stop}]
      assert build_branched_stop({stop, false}, [], {nil, []}) == [{[{nil, :terminus}], stop}]
    end

    test "non-terminus in unbranched stops is a merge stop when it's first or last in list" do
      new_stop = %RouteStop{id: "new"}
      result = build_branched_stop({new_stop, true}, [], {nil, ["branch 1", "branch 2"]})
      assert result == [{[{"branch 1", :merge}, {"branch 2", :merge}], new_stop}]
    end

    test "unbranched stops that aren't first or last in list are just :stop" do
      new_stop = %RouteStop{id: "new"}
      result = build_branched_stop({new_stop, false}, [], {nil, []})
      assert result == [{[{nil, :stop}], new_stop}]
    end

    test "branched terminus includes :terminus in stop bubbles" do
      new_stop = %RouteStop{id: "new", branch: "branch 1", is_terminus?: true}
      result = build_branched_stop({new_stop, false}, [], {"branch 1", ["branch 1", "branch 2"]})
      assert result == [{[{"branch 1", :terminus}, {"branch 2", :line}], new_stop}]
    end
  end

  describe "build_branched_stop_list" do
    test "returns stops in reverse order for both directions when branch is nil" do
      stops = ["first", "middle", "last"]
      |> Util.EnumHelpers.with_first_last()
      |> Enum.map(fn {stop_id, is_terminus?} -> %RouteStop{id: stop_id, is_terminus?: is_terminus?} end)
      outbound = build_branched_stop_list(%RouteStops{branch: nil, stops: stops}, {[], []})
      inbound = build_branched_stop_list(%RouteStops{branch: nil, stops: stops}, {[], []})
      assert outbound == inbound
      assert {[last, middle, first], []} = outbound
      assert last == {[{nil, :terminus}], %RouteStop{id: "last", is_terminus?: true}}
      assert middle == {[{nil, :stop}], %RouteStop{id: "middle", is_terminus?: false}}
      assert first == {[{nil, :terminus}], %RouteStop{id: "first", is_terminus?: true}}
    end
  end
end
