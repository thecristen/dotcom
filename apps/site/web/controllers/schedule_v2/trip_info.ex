defmodule Site.ScheduleV2.TripInfo do
  @moduledoc """
  Assigns :trip and :trip_schedule
  """
  use Plug.Builder
  alias Plug.Conn
  import Plug.Conn
  alias Schedules.Schedule

  plug :assign_trip
  plug :assign_trip_schedule

  @spec assign_trip(Conn.t, any) :: Conn.t
  defp assign_trip(%Conn{params: %{"trip" => trip}} = conn, _) do
    assign(conn, :trip, trip)
  end
  defp assign_trip(conn, _) do
    assign(conn, :trip, current_trip(conn.assigns.all_schedules))
  end

  @spec assign_trip_schedule(Conn.t, any) :: Conn.t
  def assign_trip_schedule(%Conn{assigns: %{trip: nil}} = conn, _), do: assign conn, :trip_schedule, []
  def assign_trip_schedule(%Conn{assigns: %{trip: trip_id}} = conn, _),
    do: assign conn, :trip_schedule, Schedules.Repo.schedule_for_trip(trip_id)
  def assign_trip_schedule(conn, _), do: assign conn, :trip_schedule, []

  @doc """
  If there are more trips left in a day, finds the next trip based on the current time.
  """
  @spec current_trip([Schedule.t | {Schedule.t, Schedule.t}]) :: String.t | nil
  def current_trip([%Schedule{} | _] = schedules) do
    do_current_trip schedules
  end
  def current_trip([{%Schedule{}, %Schedule{}} | _] = schedules) do
    schedules
    |> Enum.map(&(elem(&1, 0)))
    |> do_current_trip
  end
  def current_trip([]), do: nil

  @spec do_current_trip([Schedule.t|{Schedule.t, Schedule.t}]) :: String.t | nil
  def do_current_trip(schedules) do
    case Enum.find(schedules, &is_after_now?/1) do
      nil -> nil
      schedule -> schedule.trip.id
    end
  end

  @spec is_after_now?(Schedule.t) :: boolean
  def is_after_now?(%Schedules.Schedule{time: time}) do
    time
    |> Timex.after?(Util.now)
  end
end
