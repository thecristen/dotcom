defmodule Site.ScheduleV2Controller.PredictionsTest do
  use Site.ConnCase, async: true

  import Site.ScheduleV2Controller.Predictions

  defmodule PredictionTest do
    # needs to be a separate module so that it's defined before the test uses
    # it
    def all(_) do
      []
    end
  end

  @opts init([predictions_fn: &PredictionsTest.all/1])

  setup %{conn: conn} do
    conn = conn
    |> assign(:date, ~D[2017-01-01])
    |> assign(:date_time, ~N[2017-01-01T12:00:00])

    {:ok, %{conn: conn}}
  end

  describe "init/1" do
    test "defaults to using Predictions.Repo.all" do
      assert init([]) == [predictions_fn: &Predictions.Repo.all/1]
    end
  end

  describe "call/2" do
    test "when given a date that isn't the service date, assigns no predictions", %{conn: conn} do
      conn = conn
      |> assign(:date, ~D[2016-12-31])
      |> call(@opts)

      assert conn.assigns[:predictions] == []
      assert conn.assigns[:vehicle_predictions] == []
    end

    test "assigns predictions for a route, stop, and direction ID", %{conn: conn} do
      conn = conn
      |> assign(:origin, %Stops.Stop{id: "place-sstat"})
      |> assign(:destination, nil)
      |> assign(:route, %{id: "4"})
      |> assign(:direction_id, "0")
      |> call([predictions_fn: fn (opts) -> opts end])

      assert conn.assigns[:predictions] == [
        route: "4",
        stop: "place-sstat",
        direction_id: "0"
      ]
    end

    test "otherwise, assigns no predictions", %{conn: conn} do
      conn = conn
      |> call(@opts)

      assert conn.assigns[:predictions] == []
    end

    test "destination predictions are assigned if destination is assigned", %{conn: conn} do
      conn = conn
      |> assign(:origin, %Stops.Stop{id: "1148"})
      |> assign(:destination, %Stops.Stop{id: "21148"})
      |> assign(:route, %{id: "66"})
      |> assign(:direction_id, "0")
      |> call([predictions_fn: fn (opts) -> opts end])

      assert conn.assigns[:predictions] == [
        route: "66",
        stop: "1148,21148"
      ]
    end

    test "assigns a list containing predictions for every stop with a vehicle at it", %{conn: conn} do
      vehicle_locations = %{
        {"1", "place-sstat"} => %Vehicles.Vehicle{trip_id: "1", stop_id: "place-sstat", status: :incoming},
        {"2", "place-north"} =>  %Vehicles.Vehicle{trip_id: "2", stop_id: "place-north", status: :stopped}
      }
      conn = conn
      |> assign(:origin, %Stops.Stop{id: "1148"})
      |> assign(:destination, %Stops.Stop{id: "21148"})
      |> assign(:route, %{id: "66"})
      |> assign(:direction_id, "0")
      |> assign(:vehicle_locations, vehicle_locations)
      |> call([predictions_fn: & &1])

      # we transform the data into this form so that we only need to make one repo call
      assert conn.assigns.vehicle_predictions == [trip: "1,2", stop: "place-sstat,place-north"]
    end
  end
end
