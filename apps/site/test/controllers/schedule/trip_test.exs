defmodule Site.ScheduleController.TripTest do
  use Site.ConnCase, async: true

  alias Site.ScheduleController.Trip
  @valid_trip_id "32101751"

  def mock_schedule_for_trip(@valid_trip_id) do
    [%Schedules.Schedule{trip: %Schedules.Trip{id: @valid_trip_id}}]
  end
  def mock_schedule_for_trip(_), do: []

  setup _ do
    {:ok, %{opts: &mock_schedule_for_trip/1}}
  end

  test "without a trip parameter, @trip and @trip_schedule are nil", %{opts: opts, conn: conn} do
    conn = conn
    |> Trip.call(opts)

    assert conn.assigns.trip == nil
    assert conn.assigns.trip_schedule == nil
  end

  test "with an invalid trip parameter, @trip and @trip_schedule are nil", %{opts: opts, conn: conn} do
    conn = %{conn | params: %{"trip" => "invalid"}}
    |> Trip.call(opts)

    assert conn.assigns.trip == nil
    assert conn.assigns.trip_schedule == nil
  end

  test "with a valid trip parameter, @trip is the trip_id and @trip_schedule has a list of schedules",
    %{opts: opts, conn: conn} do
    conn = %{conn | params: %{"trip" => @valid_trip_id}}
    |> Trip.call(opts)

    assert conn.assigns.trip == @valid_trip_id
    assert is_list(conn.assigns.trip_schedule)
    assert List.first(conn.assigns.trip_schedule).trip.id == @valid_trip_id
  end
end
