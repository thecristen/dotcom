defmodule Site.ScheduleV2Controller.VehicleLocationsTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2Controller.VehicleLocations

  defmodule TestHelpers do
    def location_fn(_, _), do: [%Vehicles.Vehicle{status: :stopped}]
    def schedule_for_trip_fn(_), do: []
  end

  @opts [
    location_fn: &TestHelpers.location_fn/2,
    schedule_for_trip_fn: &TestHelpers.schedule_for_trip_fn/1
  ]

  setup %{conn: conn} do
    conn = conn
    |> assign(:date, ~D[2017-01-01])
    |> assign(:date_time, ~N[2017-01-01T12:00:00])
    |> assign(:route, %{id: ""})
    |> assign(:direction_id, nil)

    {:ok, %{conn: conn}}
  end

  describe "init/1" do
    test "takes no options" do
      assert init([]) == [
        location_fn: &Vehicles.Repo.route/2,
        schedule_for_trip_fn: &Schedules.Repo.schedule_for_trip/1
      ]
    end
  end

  describe "call/2" do
    @locations [
      %Vehicles.Vehicle{trip_id: "1", stop_id: "place-sstat", status: :incoming},
      %Vehicles.Vehicle{trip_id: "2", stop_id: "place-north", status: :stopped},
      %Vehicles.Vehicle{trip_id: "3", stop_id: "place-bbsta", status: :in_transit}
    ]

    test "assigns an empty map if the date isn't the service date", %{conn: conn} do
      conn = conn
      |> assign(:date, ~D[2016-12-31])
      |> call(@opts)

      assert conn.assigns.vehicle_locations == %{}
    end

    test "assigns vehicle locations at a stop if they are stopped or incoming", %{conn: conn} do
      conn = conn
      |> call(location_fn: fn (_, _) -> Enum.take(@locations, 2) end)

      assert conn.assigns.vehicle_locations == %{
        {"1", "place-sstat"} => Enum.at(@locations, 0),
        {"2", "place-north"} => Enum.at(@locations, 1)
      }
    end

    test "filters out trips with no vehicle locations", %{conn: conn} do
      conn = conn
      |> call(location_fn: fn (_, _) -> Enum.take(@locations, 1) end)

      assert conn.assigns.vehicle_locations == %{{"1", "place-sstat"} => Enum.at(@locations, 0)}
    end

    test "if a vehicle is in transit to a stop, shows the vehicle at the previous scheduled stop", %{conn: conn} do
      conn = conn
      |> call(
        [
          location_fn: fn (_, _) -> Enum.drop(@locations, 2) end,
          schedule_for_trip_fn: fn _ -> [
            %Schedules.Schedule{stop: %Schedules.Stop{id: "Yawkey"}},
            %Schedules.Schedule{stop: %Schedules.Stop{id: "place-bbsta"}},
            %Schedules.Schedule{stop: %Schedules.Stop{id: "place-sstat"}}
          ]
          end
        ]
      )

      assert conn.assigns.vehicle_locations == %{
        {"3", "Yawkey"} => Enum.at(@locations, 2)
      }
    end
  end
end
