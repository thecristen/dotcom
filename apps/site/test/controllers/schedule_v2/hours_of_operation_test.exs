defmodule Site.ScheduleV2Controller.HoursOfOperationTest do
  use Site.ConnCase, async: true

  test "if route is nil, assigns nothing", %{conn: conn} do
    conn = conn
    |> assign(:route, nil)
    |> Site.ScheduleV2Controller.HoursOfOperation.call([])

    refute Map.has_key?(conn.assigns, :hours_of_operation)
  end

  test "assigns week, saturday, and sunday departures in both directions", %{conn: conn} do
    conn = conn
    |> assign(:route, %Routes.Route{id: "Red"})
    |> Site.ScheduleV2Controller.HoursOfOperation.call([])

    assert conn.assigns.hours_of_operation[:week][0].first_departure.hour == 5
    assert conn.assigns.hours_of_operation[:week][0].last_departure.hour == 1
    assert conn.assigns.hours_of_operation[:week][1].first_departure.hour == 5
    assert conn.assigns.hours_of_operation[:saturday][1].first_departure.hour == 5
    assert conn.assigns.hours_of_operation[:sunday][1].first_departure.hour == 6
  end

  test "uses schedules for each Green line branch", %{conn: conn} do
    conn = conn
    |> assign(:route, GreenLine.green_line())
    |> Site.ScheduleV2Controller.HoursOfOperation.call([])

    assert conn.assigns.hours_of_operation[:week][0].first_departure.hour == 5
    assert conn.assigns.hours_of_operation[:week][0].last_departure.hour == 1
    assert conn.assigns.hours_of_operation[:week][1].first_departure.hour == 4
    assert conn.assigns.hours_of_operation[:week][1].last_departure.hour == 1
  end

  test "assigns nothing if there is no service", %{conn: conn} do
    conn = %{conn | params: %{"route" => "Teal"}}
    |> assign(:route, %Routes.Route{id: "Teal"})
    |> Site.ScheduleV2Controller.HoursOfOperation.call([])

    refute Map.has_key?(conn.assigns, :hours_of_operation)
  end
end
