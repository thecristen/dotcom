defmodule Site.ScheduleV2Controller.SchedulesTest do
  use Site.ConnCase, async: true
  alias Schedules.{Schedule, Trip, Stop}
  alias Routes.Route
  alias Routes.Route

  import Site.ScheduleV2Controller.Schedules

  @route %Route{id: "Red", type: 1, name: "Red"}
  @schedules [
    %Schedule{
      time: ~N[2017-01-01T07:00:00],
      route: @route
    },
    %Schedule{
      time: ~N[2017-01-01T07:30:00],
      route: @route
    },
    %Schedule{
      time: ~N[2017-01-01T07:35:00],
        route: @route
    },
    %Schedule{
      time: ~N[2017-01-01T07:40:00],
      route: @route
    }]
  @od_schedules [
    {
      %Schedule{
        time: ~N[2017-01-01T07:00:00],
        route: @route,
        stop: %Stop{id: "1"},
        trip: %Trip{id: "t2"}
      },
      %Schedule{
        time: ~N[2017-01-01T07:30:00],
        route: @route,
        stop: %Stop{id: "3"},
        trip: %Trip{id: "t2"}
      }
    },
    {
      %Schedule{
        time: ~N[2017-01-01T07:20:00],
        route: @route,
        stop: %Stop{id: "1"},
        trip: %Trip{id: "t1"}
      },
      %Schedule{
        time: ~N[2017-01-01T07:40:00],
        route: @route,
        stop: %Stop{id: "3"},
        trip: %Trip{id: "t1"}
      }
    },
    {
      %Schedule{
        time: ~N[2017-01-01T08:00:00],
        route: @route,
        stop: %Stop{id: "1"},
        trip: %Trip{id: "t3"}
      },
      %Schedule{
        time: ~N[2017-01-01T09:30:00],
        route: @route,
        stop: %Stop{id: "3"},
        trip: %Trip{id: "t3"}
      }
    }
  ]


  @bus_route %Route{id: "1", type: 3, name: "1"}
  @bus_od_schedules [
    {
      %Schedule{
        time: ~N[2017-01-01T07:00:00],
        route: @bus_route,
        stop: %Stop{id: "1"},
        trip: %Trip{id: "t2"}
      },
      %Schedule{
        time: ~N[2017-01-01T07:30:00],
        route: @bus_route,
        stop: %Stop{id: "3"},
        trip: %Trip{id: "t2"}
      }
    },
    {
      %Schedule{
        time: ~N[2017-01-01T07:20:00],
        route: @bus_route,
        stop: %Stop{id: "1"},
        trip: %Trip{id: "t1"}
      },
      %Schedule{
        time: ~N[2017-01-01T07:40:00],
        route: @bus_route,
        stop: %Stop{id: "3"},
        trip: %Trip{id: "t1"}
      }
    },
    {
      %Schedule{
        time: ~N[2017-01-01T08:00:00],
        route: @bus_route,
        stop: %Stop{id: "1"},
        trip: %Trip{id: "t3"}
      },
      %Schedule{
        time: ~N[2017-01-01T09:30:00],
        route: @bus_route,
        stop: %Stop{id: "3"},
        trip: %Trip{id: "t3"}
      }
    }
  ]

  describe "assign_frequency_table/1" do
    test "when schedules are assigned as a list, assigns a frequency table", %{conn: conn} do
      conn = conn
      |> assign_frequency_table(@schedules)

      assert conn.assigns.frequency_table.frequencies == TimeGroup.frequency_by_time_block(@schedules)
      assert conn.assigns.frequency_table.departures.first_departure == List.first(@schedules).time
    end

    test "when schedules are assigned, assigns a frequency table", %{conn: conn} do
      conn = conn
      |> assign_frequency_table(@od_schedules)

      schedules = @od_schedules # grab the departure schedule
      |> Enum.map(&elem(&1, 0))

      assert conn.assigns.frequency_table.frequencies == TimeGroup.frequency_by_time_block(schedules)
      assert conn.assigns.frequency_table.departures.first_departure == elem(List.first(@od_schedules), 0).time
    end

    test "when schedules are light rail, assigns a frequency table", %{conn: conn} do
      route = %Routes.Route{type: 0, id: "Green-B", name: "Green B"}
      schedules = @schedules
      |> Enum.map(& %{&1 | route: route})

      conn = conn
      |> assign_frequency_table(schedules)

      assert conn.assigns.frequency_table.frequencies == TimeGroup.frequency_by_time_block(schedules)
      assert conn.assigns.frequency_table.departures.first_departure == List.first(@schedules).time
    end

    test "does not assign a frequency table for non-subway routes", %{conn: conn} do
      conn = conn
      |> assign_frequency_table(@bus_od_schedules)

      refute :frequency_table in Map.keys(conn.assigns)
    end
  end
end
