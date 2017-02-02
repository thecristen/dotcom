defmodule Site.ScheduleV2Controller.PredictionsTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2Controller.Predictions

  describe "init/1" do
    test "takes no options" do
      assert init([]) == []
    end
  end

  describe "call/2" do
    test "when given a date that isn't the service date, assigns no predictions" do
      conn = build_conn()
      |> assign(:date, Util.service_date() |> Timex.shift(days: -1))
      |> call([])

      assert conn.assigns[:predictions] == []
    end

    test "assigns predictions for a route, stop, and direction ID" do
      conn = build_conn()
      |> assign(:origin, %Stops.Stop{id: "place-sstat"})
      |> assign(:destination, nil)
      |> assign(:route, %{id: "4"})
      |> assign(:direction_id, "0")
      |> call([predictions_fn: fn (opts) -> opts end])

      assert conn.assigns[:predictions] == [
        direction_id: "0",
        stop: "place-sstat,",
        route: "4"
      ]
    end

    test "otherwise, assigns no predictions" do
      conn = build_conn()
      |> call([])

      assert conn.assigns[:predictions] == []
    end

    test "destination predictions are assigned if destination is assigned" do
      conn = build_conn()
      |> assign(:origin, %Stops.Stop{id: "1148"})
      |> assign(:destination, %Stops.Stop{id: "21148"})
      |> assign(:route, %{id: "66"})
      |> assign(:direction_id, "0")
      |> call([predictions_fn: fn (opts) -> opts end])

      assert conn.assigns[:predictions] == [
        direction_id: "0",
        stop: "1148,21148",
        route: "66"
      ]
    end
  end

  describe "gather_vehicle_predictions/2" do
    test "assigns a list containing predictions for every stop with a vehicle at it" do
      vehicle_locations = %{
        {"1", "place-sstat"} => %Vehicles.Vehicle{trip_id: "1", stop_id: "place-sstat", status: :incoming},
        {"2", "place-north"} =>  %Vehicles.Vehicle{trip_id: "2", stop_id: "place-north", status: :stopped}
      }
      conn = build_conn()
      |> assign(:origin, %Stops.Stop{id: "1148"})
      |> assign(:destination, %Stops.Stop{id: "21148"})
      |> assign(:route, %{id: "66"})
      |> assign(:direction_id, "0")
      |> assign(:vehicle_locations, vehicle_locations)
      |> gather_vehicle_predictions(fn x -> x end)

      assert conn.assigns.vehicle_predictions == [trip: "1", stop: "place-sstat", trip: "2", stop: "place-north"]
    end
  end
end
