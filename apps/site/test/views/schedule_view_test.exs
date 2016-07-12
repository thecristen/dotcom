defmodule Site.ScheduleViewTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @stop %Schedules.Stop{id: "stop_id"}
  @trip %Schedules.Trip{id: "trip_id"}
  @route %Routes.Route{type: 2, id: "route_id"}
  @schedule %Schedules.Schedule{stop: @stop, trip: @trip, route: @route}

  test "has_alerts? returns false if the only alert affects the whole route" do
    all_rail_alert = %Alerts.Alert{informed_entity: [%Alerts.InformedEntity{route_type: @route.type}]}
    all_line_alert = %Alerts.Alert{informed_entity: [%Alerts.InformedEntity{route_type: @route.type, route: @route.id}]}

    refute Site.ScheduleView.has_alerts?([all_rail_alert, all_line_alert], @schedule)
  end

  test "has_alerts? returns true if the alert affects the whole route and is a delay" do
    all_line_delay = %Alerts.Alert{
      effect_name: "Delay",
      informed_entity: [%Alerts.InformedEntity{route_type: @route.type, route: @route.id}]}

    assert Site.ScheduleView.has_alerts?([all_line_delay], @schedule)
  end

  test "has_alerts? returns true if there's an alert for the trip" do
    trip_alert = %Alerts.Alert{informed_entity: [%Alerts.InformedEntity{trip: @trip.id}]}

    assert Site.ScheduleView.has_alerts?([trip_alert], @schedule)
  end
end
