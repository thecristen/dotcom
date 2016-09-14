defmodule Site.ScheduleController.Trip do
  @moduledoc """
  If a trip is selected (via the `trip` parameter), fetches that trip and assigns
  it as @trip_schedule.  Otherwise, assigns nil to @trip.
  """

  import Plug.Conn, only: [assign: 3]

  def init([]), do: []

  def call(%{params: %{"trip" => trip_id}} = conn, []) when not is_nil(trip_id) do
    conn
    |> do_selected_trip(Schedules.Repo.trip(trip_id))
  end
  def call(conn, []) do
    conn
    |> do_selected_trip(nil)
  end

  def do_selected_trip(conn, [%Schedules.Schedule{trip: %{id: trip_id}} | _] = trips) do
    conn
    |> assign(:trip, trip_id)
    |> assign(:trip_schedule, trips)
  end
  def do_selected_trip(conn, _) do
    conn
    |> assign(:trip, nil)
    |> assign(:trip_schedule, nil)
  end
end
