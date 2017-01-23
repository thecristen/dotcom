defmodule Site.ScheduleV2.DatePickerTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2.DatePicker

  @opts init([])

  test "assigns date_select == false when there are no params", %{conn: conn} do
    conn = %{conn | query_params: %{}}
    |> call(@opts)

    assert conn.assigns.date_select == false
    refute :holidays in conn.assigns
    refute :calendar in conn.assigns
  end

  test "assigns date_select, holidays, calendar when date_select == true", %{conn: conn} do
    conn = %{conn |
             params: %{"route" => "route", "date_select" => "true"},
             query_params: %{"date_select" => "true"}}
    |> assign(:date, ~D[2017-01-01])
    |> call(@opts)

    assert conn.assigns.date_select == true
    assert conn.assigns.holidays == Holiday.Repo.holidays_in_month(~D[2017-01-15])

    calendar = conn.assigns.calendar
    assert %BuildCalendar.Calendar{} = calendar
    assert List.first(calendar.days).url =~ "?date=2017-01-01"
  end
end
