defmodule Site.ScheduleView.CalendarTest do
  use ExUnit.Case, async: true
  use Site.ConnCase, async: true
  alias Site.ScheduleView.Calendar
  import Phoenix.HTML, only: [safe_to_string: 1]

  describe "Building calendar" do
    test "Calendars do not have empty weeks", %{conn: conn} do
      conn = %{conn | params: %{"route" => "route"}}

      sunday_start = ~D[2017-01-01]
      monday_start = ~D[2017-05-01]
      sunday_start_links = Calendar.build_calendar(sunday_start, [], conn)
      monday_start_links = Calendar.build_calendar(monday_start, [], conn)

      sunday_blank_dates = sunday_start_links |> Enum.take_while(fn x -> not(safe_to_string(x) =~ "href") end)
      monday_blank_dates = monday_start_links |> Enum.take_while(fn x -> not(safe_to_string(x) =~ "href") end)

      assert Enum.count(sunday_blank_dates) == 0
      assert Enum.count(monday_blank_dates) == 1
    end
    test "There are no empty dates at end of calendar", %{conn: conn} do
      conn = %{conn | params: %{"route" => "route"}}
      sunday_start = ~D[2017-01-01]
      saturday_start = ~D[2017-07-01]
      sunday_start_links = Calendar.build_calendar(sunday_start,[], conn)
      saturday_start_links = Calendar.build_calendar(saturday_start, [], conn)

      assert rem(Enum.count(sunday_start_links), 7) == 0
      assert rem(Enum.count(saturday_start_links), 7) == 0
    end
    test "Holidays are marked", %{conn: conn} do
      conn = %{conn | params: %{"route" => "route"}}
      holiday = %Holiday{name: "Memorial Day", date: ~D[2017-05-30]}
      current_day = ~D[2017-05-20]
      may_calendar = Calendar.build_calendar(current_day, [holiday], conn)
      holiday_link = Enum.find(may_calendar, nil, fn x -> safe_to_string(x) =~ "2017-05-30" end)
      assert safe_to_string(holiday_link) =~ "holiday"
    end
  end
end
