defmodule Alerts.TripTest do
  use ExUnit.Case, async: true
  alias Alerts.Alert
  alias Alerts.InformedEntity, as: IE
  alias Alerts.Trip

  @trip_id "trip_id"
  @route_id "route_id"

  test "includes alerts that apply directly to the given trip" do
    alert = %Alert{informed_entity: [%IE{trip: @trip_id}]}
    wrong_alert = %Alert{informed_entity: [%IE{trip: "other trip"}]}

    assert [alert] == Trip.match([alert, wrong_alert], @trip_id)
  end

  test "includes delays that apply to the route" do
    alert = %Alert{
      effect_name: "Delay",
      informed_entity: [%IE{route: @route_id}]}
    wrong_route = %Alert{
      header: "Wrong Route",
      effect_name: "Delay",
      informed_entity: [%IE{route: "other route"}]}
    wrong_effect = %Alert{
      header: "Wrong Effect",
      informed_entity: [%IE{route: @route_id}]}

    assert [alert] == Trip.match([alert, wrong_route, wrong_effect], @trip_id, route: @route_id)
  end

  test "does not double-count delays on a trip" do
    alert = %Alert{
      effect_name: "Delay",
      informed_entity: [%IE{trip: @trip_id}]}

    assert [alert] == Trip.match([alert], @trip_id)
  end

  test "includes delays that are active at :time" do
    now = Timex.DateTime.now
    alert = %Alert{informed_entity: [%IE{trip: @trip_id}],
                   active_period: [{now, nil}]}
    wrong_alert = %Alert{informed_entity: [%IE{trip: @trip_id}],
                        active_period: []}

    assert [alert] == Trip.match([alert, wrong_alert], @trip_id, time: now)
  end
end
