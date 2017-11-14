defmodule SiteWeb.ScheduleV2Controller.HoursOfOperationTest do
  use SiteWeb.ConnCase, async: true

  test "if route is nil, assigns nothing", %{conn: conn} do
    conn = conn
    |> assign(:route, nil)
    |> assign(:date, Util.service_date())
    |> SiteWeb.ScheduleV2Controller.HoursOfOperation.call([])

    refute Map.has_key?(conn.assigns, :hours_of_operation)
  end

  test "assigns week, saturday, and sunday departures in both directions", %{conn: conn} do
    conn = conn
    |> assign(:route, %Routes.Route{id: "Red"})
    |> assign(:date, Util.service_date())
    |> SiteWeb.ScheduleV2Controller.HoursOfOperation.call([])

    assert %Schedules.HoursOfOperation{} = conn.assigns.hours_of_operation
  end

  test "uses schedules for each Green line branch", %{conn: conn} do
    conn = conn
    |> assign(:route, GreenLine.green_line())
    |> assign(:date, Util.service_date())
    |> SiteWeb.ScheduleV2Controller.HoursOfOperation.call([])

    assert %Schedules.HoursOfOperation{} = conn.assigns.hours_of_operation
  end

  test "assigns nothing if there is no service", %{conn: conn} do
    conn = conn
    |> assign(:route, %Routes.Route{id: "Teal"})
    |> assign(:date, Util.service_date())
    |> SiteWeb.ScheduleV2Controller.HoursOfOperation.call([])

    refute Map.has_key?(conn.assigns, :hours_of_operation)
  end
end
