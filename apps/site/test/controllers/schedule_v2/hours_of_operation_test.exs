defmodule Site.ScheduleV2Controller.HoursOfOperationTest do
  use Site.ConnCase, async: true

  defp schedules_fn(_route_ids, opts) do
    date_time = Timex.to_datetime(opts[:date])
    [
      %Schedules.Schedule{time: Timex.set(date_time, hour: 6), trip: %Schedules.Trip{id: "1", direction_id: 0}},
      %Schedules.Schedule{time: Timex.set(date_time, hour: 23), trip: %Schedules.Trip{id: "2", direction_id: 0}},
      %Schedules.Schedule{time: Timex.set(date_time, hour: 6), trip: %Schedules.Trip{id: "3", direction_id: 1}},
      %Schedules.Schedule{time: Timex.set(date_time, hour: 23), trip: %Schedules.Trip{id: "4", direction_id: 1}},
    ]
  end

  defp no_service_fn(_route_ids, _opts) do
    {:error,
      [%JsonApi.Error{code: "no_service",
        detail: nil,
        meta: %{"end_date" => "2017-09-01",
                "start_date" => "2017-06-08",
                "version" => "Summer 2017 version 2D, 6/8/17"},
        source: %{"parameter" => "date"}}]}
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
    |> Site.ScheduleV2Controller.HoursOfOperation.call(schedules_fn: &schedules_fn/2)

    assert conn.assigns.hours_of_operation[:week][0].first_departure.hour == 6
    assert conn.assigns.hours_of_operation[:week][0].last_departure.hour == 23
    assert conn.assigns.hours_of_operation[:week][1].first_departure.day == 6 # Monday
    assert conn.assigns.hours_of_operation[:sunday][1].first_departure.day == 5
    assert conn.assigns.hours_of_operation[:saturday][1].first_departure.day == 4
  end

  test "uses schedules for each Green line branch", %{conn: conn} do
    conn = conn
    |> assign(:route, GreenLine.green_line())
    |> assign(:date, ~D[2017-02-28])
    |> Site.ScheduleV2Controller.HoursOfOperation.call(schedules_fn: &schedules_fn/2)

    assert conn.assigns.hours_of_operation[:week][0].first_departure.hour == 6
    assert conn.assigns.hours_of_operation[:week][0].last_departure.hour == 23
  end

  test "assigns nothing if there is no service", %{conn: conn} do
    conn = %{conn | params: %{"route" => "Teal"}}
    |> assign(:route, %Routes.Route{id: "Teal"})
    |> assign(:date, ~D[2017-02-28])
    |> Site.ScheduleV2Controller.HoursOfOperation.call(schedules_fn: &no_service_fn/2)

    refute Map.has_key?(conn.assigns, :hours_of_operation)
  end
end
