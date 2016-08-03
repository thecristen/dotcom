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
    trip_alert = %Alerts.Alert{effect_name: "Delay", informed_entity: [%Alerts.InformedEntity{trip: @trip.id}]}

    assert Site.ScheduleView.has_alerts?([trip_alert], @schedule)
  end

  test "reverse_direction_opts reverses direction when the stop exists in the other direction" do
    expected = [trip: "", direction_id: "1", dest: "place-harsq", origin: "place-davis", route: "Red"]
    actual = Site.ScheduleView.reverse_direction_opts("place-harsq", "place-davis", "Red", "1")
    assert Keyword.equal?(expected, actual)
  end

  test "reverse_direction_opts doesn't maintain stops when the stop does not exist in the other direction" do
    expected = [trip: "", direction_id: "1", dest: nil, origin: nil, route: "16"]
    actual = Site.ScheduleView.reverse_direction_opts("111", "2905", "16", "1")
    assert Keyword.equal?(expected, actual)
  end

  test "test display_alert_effects returns one alert for one effect" do
    delay_alert = %Alerts.Alert{effect_name: "Delay"}

    expected = "Delay"
    actual = Site.ScheduleView.display_alert_effects([delay_alert])

    assert expected == actual
  end
end
