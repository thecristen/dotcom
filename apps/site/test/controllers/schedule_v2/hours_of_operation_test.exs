defmodule Site.ScheduleV2Controller.HoursOfOperationTest do
  use Site.ConnCase, async: true

  defp schedules_fn(opts) do
    date_time = Timex.to_datetime(opts[:date])
    [
      %Schedules.Schedule{time: Timex.set(date_time, hour: 6), trip: %Schedules.Trip{direction_id: 0}},
      %Schedules.Schedule{time: Timex.set(date_time, hour: 23), trip: %Schedules.Trip{direction_id: 0}},
      %Schedules.Schedule{time: Timex.set(date_time, hour: 6), trip: %Schedules.Trip{direction_id: 1}},
      %Schedules.Schedule{time: Timex.set(date_time, hour: 23), trip: %Schedules.Trip{direction_id: 1}},
    ]
  end

  test "if route is nil, assigns nothing", %{conn: conn} do
    conn = conn
    |> assign(:route, nil)
    |> assign(:date, ~D[2017-02-28])
    |> Site.ScheduleV2Controller.HoursOfOperation.call([])

    refute Map.has_key?(conn.assigns, :hours_of_operation)
  end

  test "assigns week, saturday, and sunday departures in both directions", %{conn: conn} do
    conn = %{conn | params: %{"route" => "Teal"}}
    |> assign(:route, %Routes.Route{id: "Teal"})
    |> assign(:date, ~D[2017-02-28]) # Tuesday
    |> Site.ScheduleV2Controller.HoursOfOperation.call(schedules_fn: &schedules_fn/1)

    assert conn.assigns.hours_of_operation[:week][0].first_departure.hour == 6
    assert conn.assigns.hours_of_operation[:week][0].last_departure.hour == 23
    assert conn.assigns.hours_of_operation[:week][1].first_departure.day == 6 # Monday
    assert conn.assigns.hours_of_operation[:sunday][1].first_departure.day == 5
    assert conn.assigns.hours_of_operation[:saturday][1].first_departure.day == 4
  end

  test "uses schedules for each Green line branch", %{conn: conn} do
    conn = %{conn | params: %{"route" => "Green"}}
    |> assign(:route, nil)
    |> assign(:date, ~D[2017-02-28])
    |> Site.ScheduleV2Controller.HoursOfOperation.call(schedules_fn: &schedules_fn/1)

    assert conn.assigns.hours_of_operation[:week][0].first_departure.hour == 6
    assert conn.assigns.hours_of_operation[:week][0].last_departure.hour == 23
  end
end
