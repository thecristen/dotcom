defmodule Site.ScheduleV2ViewTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2View
  import Phoenix.HTML, only: [safe_to_string: 1]
  alias Schedules.Stop

  describe "display_direction/1" do
    test "given no schedules, returns no content" do
      assert display_direction([]) == ""
    end

    test "given a non-empty list of schedules, displays the direction of the first schedule's route" do
      schedules = [
        %Schedules.Schedule{route: %Routes.Route{id: "Red"}, trip: %Schedules.Trip{direction_id: 1}}
      ]
      assert schedules |> display_direction |> IO.iodata_to_binary == "Northbound to"
    end
  end

  describe "update_schedule_url/2" do
    test "adds additional parameters to a conn", %{conn: conn} do
      conn = %{conn | params: %{"route" => "route"}}

      actual = update_schedule_url(conn, trip: "trip")
      expected = bus_path(conn, :show, "route", trip: "trip")

      assert expected == actual
    end

    test "updates existing parameters in a conn", %{conn: conn} do
      conn = %{conn | params: %{"route" => "route", "trip" => "old"}}

      actual = update_schedule_url(conn, trip: "trip")
      expected = bus_path(conn, :show, "route", trip: "trip")

      assert expected == actual
    end

    test "setting a value to nil removes it from the URL", %{conn: conn} do
      conn = %{conn | params: %{"route" => "route", "trip" => "trip"}}

      actual = update_schedule_url(conn, trip: nil)
      expected = bus_path(conn, :show, "route")

      assert expected == actual
    end

    test 'setting a value to "" keeps it from the URL', %{conn: conn} do
      conn = %{conn | params: %{"route" => "route", "trip" => "trip"}}

      actual = update_schedule_url(conn, trip: "")
      expected = bus_path(conn, :show, "route", trip: "")

      assert expected == actual
    end
  end

  describe "stop_info_link/1" do
    test "generates a stop link on a map icon when the stop has stop information" do
      stop = %Stop{id: "place-sstat"}
      str = safe_to_string(stop_info_link(stop))
      assert str =~ stop_path(Site.Endpoint, :show, "place-sstat")
      assert str =~ safe_to_string(svg_icon(%{icon: :map}))
      assert str =~ "View stop information for South Station"
    end

    test "generates a stop link on a map icon for a bus stop that is not a station" do
      stop = %Stop{id: "1736"}
      str = safe_to_string(stop_info_link(stop))
      assert str =~ stop_path(Site.Endpoint, :show, "1736")
      assert str =~ safe_to_string(svg_icon(%{icon: :map}))
      assert str =~ "View stop information for Blue Hill Ave opp Health Ctr"
    end
  end

  describe "Shifting months" do
    test "Months are not skipped when shifting" do
      date = ~D[2016-02-28]
      assert add_month(date).month == 3
      assert decrement_month(date).month == 1
    end
    test "Years are incremented on when shifting to new year" do
      date = ~D[2016-12-31]
      shifted_date = add_month(date)
      assert shifted_date.month == 1
      assert shifted_date.year == 2017
    end
  end

  describe "previous_month_class/1" do
    test "disables the link if the given date is in the current month" do
      assert previous_month_class(Util.today) == " disabled"
    end

    test "disables the link if the given date is in a previous month" do
      assert Util.today |> Timex.shift(months: -2) |> previous_month_class == " disabled"
    end

    test "leaves the link enabled if the given date is in a future month" do
      assert Util.today |> Timex.shift(months: 2) |> previous_month_class == ""
    end
  end
end
