defmodule Stops.RouteStopTest do
  use ExUnit.Case, async: true

  import Stops.RouteStop
  alias Stops.Stop
  alias Routes.{Route, Shape}

  describe "build_route_stop/3" do
    test "creates a RouteStop object with all expected attributes" do
      stop = %Stop{name: "Braintree", id: "place-brntn"}
      result = build_route_stop({{stop, true}, 2000}, %Routes.Shape{name: "Braintree"}, %Routes.Route{id: "Red", type: 1})
      assert result.id == "place-brntn"
      assert result.name == "Braintree"
      assert result.station_info == stop
      assert result.is_terminus? == true
      assert result.zone == "2"
      assert result.stop_number == 2000
      assert result.stop_features == ~w(commuter_rail bus)a
    end
  end

  describe "list_from_shapes/4" do
    test "handles Red line when Ashmont/Braintree are first" do
      ashmont_shape = %Shape{
        id: "ashmont",
        name: "Ashmont",
        stop_ids: ~w(alewife shared ashmont)s
      }
      braintree_shape = %Shape{
        id: "braintree",
        name: "Braintree",
        stop_ids: ~w(alewife shared braintree)s
      }
      stops = make_stops(~w(braintree ashmont shared alewife)s)
      route = %Route{id: "Red"}
      actual = list_from_shapes([ashmont_shape, braintree_shape], stops, route, 0)

      assert_stop_ids(actual, ~w(alewife shared braintree ashmont)s)
      assert_branch_names(actual, [nil, nil, "Braintree", "Ashmont"])
    end

    test "handles Red line when Ashmont/Braintree are last" do
      ashmont_shape = %Shape{
        id: "ashmont",
        name: "Ashmont",
        stop_ids: ~w(ashmont shared alewife)s
      }
      braintree_shape = %Shape{
        id: "braintree",
        name: "Braintree",
        stop_ids: ~w(braintree shared alewife)s
      }
      stops = make_stops(~w(braintree ashmont shared alewife)s)
      route = %Route{id: "Red"}
      actual = list_from_shapes([ashmont_shape, braintree_shape], stops, route, 1)

      assert_stop_ids(actual, ~w(ashmont braintree shared alewife))
      assert_branch_names(actual, ["Ashmont", "Braintree", nil, nil])
    end

    test "handles Kingston where the Plymouth branch doesn't have JFK (outbound)" do
      kingston = %Shape{
        id: "kingston",
        name: "Kingston",
        stop_ids: ~w(sstat jfk braintree kingston)s
      }
      plymouth = %Shape{
        id: "plymouth",
        name: "Plymouth",
        stop_ids: ~w(sstat braintree plymouth)s
      }
      stops = make_stops(~w(sstat jfk braintree kingston plymouth)s)
      route = %Route{id: "CR-Kingston"}
      actual = list_from_shapes([kingston, plymouth], stops, route, 0)

      assert_stop_ids(actual, ~w(sstat jfk braintree plymouth kingston))
      assert_branch_names(actual, [nil, nil, nil, "Plymouth", "Kingston"])
    end

    test "handles Kingston where the Plymouth branch doesn't have JFK (inbound)" do
      kingston = %Shape{
        id: "kingston",
        name: "Kingston",
        stop_ids: ~w(kingston braintree jfk sstat)s
      }
      plymouth = %Shape{
        id: "plymouth",
        name: "Plymouth",
        stop_ids: ~w(plymouth braintree sstat)s
      }
      stops = make_stops(~w(sstat jfk braintree kingston plymouth)s)
      route = %Route{id: "CR-Kingston"}
      actual = list_from_shapes([kingston, plymouth], stops, route, 1)

      assert_stop_ids(actual, ~w(kingston plymouth braintree jfk sstat)s)
      assert_branch_names(actual, ["Kingston", "Plymouth", nil, nil, nil])
    end
  end

  defp make_stops(stop_ids) do
    for id <- stop_ids do
      %Stop{id: id, name: id}
    end
  end

  def assert_stop_ids(actual, stop_ids) do
    assert Enum.map(actual, & &1.id) == stop_ids
  end

  def assert_branch_names(actual, branch_names) do
    assert Enum.map(actual, & &1.branch) == branch_names
  end
end
