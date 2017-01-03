defmodule Site.Plugs.ScheduleV2.Trip do
  @moduledoc """
  If a trip is selected (via the `trip` parameter), fetches that trip and assigns
  it as @trip_schedule.  Otherwise, assigns nil to @trip.
  """

  import Plug.Conn, only: [assign: 3]

  def init([]), do: &Schedules.Repo.schedule_for_trip/1

  def call(%{params: %{"trip" => ""}} = conn, _) do
    # if we explicitly set trip to an empty string, then don't include a
    # default trip
    conn
    |> assign(:trip, nil)
    |> assign(:trip_schedule, nil)
  end
  def call(%{params: %{"trip" => trip_id}} = conn, schedule_for_trip_fn) when not is_nil(trip_id) do
    conn
    |> do_selected_trip(schedule_for_trip_fn.(trip_id))
  end
  def call(%{assigns: %{schedules: schedules}} = conn, schedule_for_trip_fn) do
    case current_trip(schedules) do
      nil -> conn
      |> assign(:trip, nil)
      |> assign(:trip_schedule, nil)
      trip_id -> do_selected_trip(conn, schedule_for_trip_fn.(trip_id))
    end
  end
  def call(conn, _) do
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

  def current_trip([%Schedules.Schedule{} | _] = schedules) do
    do_current_trip schedules
  end
  def current_trip([{%Schedules.Schedule{}, %Schedules.Schedule{}} | _] = schedules) do
    schedules
    |> Enum.map(&(elem(&1, 0)))
    |> do_current_trip
  end
  def current_trip([]), do: nil

  def do_current_trip(schedules) do
    case Enum.find_index(schedules, &is_after_now?/1) do
      nil -> nil
      index -> Enum.at(schedules, index).trip.id
    end
  end

  def is_after_now?(%Schedules.Schedule{time: time}) do
    time
    |> Timex.after?(Util.now)
  end
end
